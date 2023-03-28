# License

import numpy as np
from librosa import load

from SRes_methods.GL import GL
from SRes_methods.RTISI import RTISI
from SRes_methods.RTISI_LA import RTISI_LA

class AudioManager():
    # AudioManager class for storing and managing information about an audio signal,
    # such as its file path, its time-frequency representations, its 
    # sampling rate, etc, and for performing signal reconstruction on 
    # the stored time-frequency representations.
    #
    # Attributes:
    # -----------
    # origin: str, path to the original audio file
    # matlab_engine: matlab.engine object
    # matlab_array: numpy.ndarray, contains the audio signal as a MATLAB array
    # matlab_sampling_f: int, sampling frequency of the audio from MATLAB method
    # np_array: numpy.ndarray, contains the audio signal as a numpy array
    # np_sampling_f: int, sampling frequency of the audio from Python method
    # RTF_tensor: numpy.ndarray, time-frequency representations of the audio
    # MRTF_tensor: numpy.ndarray, modified time-frequency representations of the audio
    #
    # Methods:
    # --------

    def __init__(self, path: str, eng) -> None:
        # Constructor for AudioManager class

        self.origin = path
        self.matlab_engine = eng
        self.matlab_array, self.matlab_sampling_f = eng.audioread(path)
        self.np_array, self.np_sampling_f = load(path,mono=True)

        self.RTF_tensor = None
        self.MRTF_tensor = None
