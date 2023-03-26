# License

import numpy as np
from librosa import load

from SRes_methods.GL import GL
from SRes_methods.RTISI import RTISI
from SRes_methods.RTISI_LA import RTISI_LA

class Audio():
    # Audio class for storing and managing information about an audio signal,
    # such as its file path, its time-frequency representations, its 
    # sampling rate, etc, and for performing signal reconstruction on 
    # the stored time-frequency representations.
    #
    # Attributes:
    #     path: str, path to the audio file
    #     matlab_engine: matlab.engine object
    #     RTF_tensor: numpy.ndarray, time-frequency representation of the audio
    #
    # Methods:

    def __init__(self, path: str, eng) -> None:
        # Constructor for Audio class

        self.origin = path
        self.matlab_engine = eng
        self.matlab_array, self.matlab_sampling_f = eng.audioread(path)
        self.np_array, self.np_sampling_f = load(path,mono=True)

        self.RTF_tensor = None

