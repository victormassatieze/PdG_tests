function ODG = PQevalAudio (Fref, Ftest, StartS, EndS)
% Perceptual evaluation of audio quality.

% - StartS shifts the frames, so that the first frame starts at that sample.
%   This is a two element array, one element for each input file. If StartS is
%   a scalar, it applies to both files.
% - EndS marks the end of data. The processing stops with the last frame that
%   contains that sample. This is a two element array, one element for each
%   input file.  If EndS is as scalar, it applies to both files.

% P. Kabal $Revision: 1.2 $  $Date: 2004/02/05 04:25:24 $

% Globals (to save on copying in/out of functions)
global MOVC PQopt

% Analysis parameters
NF = 2048;
Nadv = NF / 2;
Version = 'Basic';

% Options
PQopt.ClipMOV = 0;
PQopt.PCinit = 0;
PQopt.PDfactor = 1;
PQopt.Ni = 1;
PQopt.DelayOverlap = 1;
PQopt.DataBounds = 1;
PQopt.EndMin = NF / 2;

addpath ('CB', 'MOV', 'Misc', 'Patt');

if (nargin < 3)
    StartS = [0, 0];
end
if (nargin < 4)
    EndS = [];
end

% Get the number of samples and channels for each file
WAV(1) = PQwavFilePar (Fref);
WAV(2) = PQwavFilePar (Ftest);

% Reconcile file differences
PQ_CheckWAV (WAV);
if (WAV(1).Nframe ~= WAV(2).Nframe)
    disp ('>>> Number of samples differ: using the minimum');
end

% Data boundaries
Nchan = WAV(1).Nchan;
[StartS, Fstart, Fend] = PQ_Bounds (WAV, Nchan, StartS, EndS, PQopt);

% Number of PEAQ frames
Np = Fend - Fstart + 1;
if (PQopt.Ni < 0)
    PQopt.Ni = ceil (Np / abs(PQopt.Ni));
end

% Initialize the MOV structure
MOVC = PQ_InitMOVC (Nchan, Np);

% Initialize the filter memory
Nc = PQCB (Version);
for (j = 0:Nchan-1)
    Fmem(j+1) = PQinitFMem (Nc, PQopt.PCinit);
end

is = 0;
for (i = -Fstart:Np-1)

    % Read a frame of data
    xR = PQgetData (WAV(1), StartS(1) + is, NF);    % Reference file
    xT = PQgetData (WAV(2), StartS(2) + is, NF);    % Test file
    is = is + Nadv;

    % Process a frame
    for (j = 0:Nchan-1)
        [MOVI(j+1), Fmem(j+1)] = PQeval (xR(j+1,:), xT(j+1,:), Fmem(j+1));
    end

    if (i >= 0)
        % Move the MOV precursors into a new structure
        PQframeMOV (i, MOVI);   % Output is in global MOVC

        % Print the MOV precursors
        if (PQopt.Ni ~= 0 & mod (i, PQopt.Ni) == 0)
            PQprtMOVCi (Nchan, i, MOVC);
        end
    end
end

% Time average of the MOV values
if (PQopt.DelayOverlap)
    Nwup = Fstart;
else
    Nwup = 0;
end
MOVB = PQavgMOVB (MOVC, Nchan, Nwup);

% Neural net
ODG = PQnNet (MOVB)

% Summary print
%PQprtMOV (MOVB, ODG);

%----------
function PQ_CheckWAV (WAV)
% Check the file parameters

Fs = 48000;

if (WAV(1).Nchan ~= WAV(2).Nchan)
    error ('>>> Number of channels differ');
end
if (WAV(1).Nchan > 2)
    error ('>>> Too many input channels');
end
if (WAV(1).Nframe ~= WAV(2).Nframe)
    disp ('>>> Number of samples differ');
end
if (WAV(1).Fs ~= WAV(2).Fs)
    error ('>>> Sampling frequencies differ');
end
if (WAV(1).Fs ~= Fs)
    error ('>>> Invalid Sampling frequency: only 48 kHz supported');
end

%----------
function [StartS, Fstart, Fend] = PQ_Bounds (WAV, Nchan, StartS, EndS, PQopt)

PQ_NF = 2048;
PQ_NADV = (PQ_NF / 2);

if (isempty (StartS))
    StartS(1) = 0;
    StartS(2) = 0;
elseif (length (StartS) == 1)
    StartS(2) = StartS(1);
end
Ns = WAV(1).Nframe;

% Data boundaries (determined from the reference file)
if (PQopt.DataBounds)
    Lim = PQdataBoundary (WAV(1), Nchan, StartS(1), Ns);
    fprintf ('PEAQ Data Boundaries: %ld (%.3f s) - %ld (%.3f s)\n', ...
             Lim(1), Lim(1)/WAV(1).Fs, Lim(2), Lim(2)/WAV(1).Fs);
else
    Lim = [Starts(1), StartS(1) + Ns - 1];
end
         
% Start frame number
Fstart = floor ((Lim(1) - StartS(1)) / PQ_NADV);

% End frame number
Fend = floor ((Lim(2) - StartS(1) + 1 - PQopt.EndMin) / PQ_NADV);

%----------
function MOVC = PQ_InitMOVC (Nchan, Np)
MOVC.MDiff.Mt1B = zeros (Nchan, Np);
MOVC.MDiff.Mt2B = zeros (Nchan, Np);
MOVC.MDiff.Wt   = zeros (Nchan, Np);

MOVC.NLoud.NL   = zeros (Nchan, Np);

MOVC.Loud.NRef  = zeros (Nchan, Np);
MOVC.Loud.NTest = zeros (Nchan, Np);

MOVC.BW.BWRef  = zeros (Nchan, Np);
MOVC.BW.BWTest = zeros (Nchan, Np);

MOVC.NMR.NMRavg = zeros (Nchan, Np);
MOVC.NMR.NMRmax = zeros (Nchan, Np);

MOVC.PD.Pc = zeros (1, Np);
MOVC.PD.Qc = zeros (1, Np);

MOVC.EHS.EHS = zeros (Nchan, Np);
