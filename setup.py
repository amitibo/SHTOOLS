import setuptools
import popen2
import os
import tempfile
import shlex
import numpy
import glob
import sys
import os


NAME = "shtools"
EXTENSION_NAME = "pyshtools"
DESCRIPTION = "Python wrapper to the SHTOOLS algorithm"
LONG_DESCRIPTION ="""Python wrapper to the SHTOOLS algorithm"""
MAINTAINER = "Amit Aides"
MAINTAINER_EMAIL = "amitibo@tx.technion.ac.il"
URL = "https://bitbucket.org/amitibo/pyshdom"
LICENSE = "MIT"
VERSION = "0.0.1"

classifiers =  ['Development Status :: 3 - Alpha',
                'Programming Language :: Python',
                'License :: OSI Approved :: MIT License',
                'Intended Audience :: Science/Research',
                'Topic :: Scientific/Engineering',
                'Topic :: Scientific/Engineering :: Mathematics',
                'Operating System :: OS Independent']

#
# Set this to True for compiling the parallel
# version of the SHDOM algorithm.
#
PARALLEL_SUPPORT = False

#
# f2py stuff
#
F2PY_CMD = 'f2py'
F2PY_MODULE_NAME = '_SHTOOLS'
F2PY_SRC_PATH = 'src'
F2PY_SIGN_FILE = '{path}/pyshtools.pyf'.format(path=F2PY_SRC_PATH)
F2PY_SHTOOLS_FILES = glob.glob('{path}/*.f95'.format(path=F2PY_SRC_PATH))
SRCSLAPACK2 = ['EigValSym2.f95', 'EigValVecSym2.f95', 'EigValVecSymTri2.f95', 'SHExpandLSQ2.f95', 'SHMTDebias2.f95', 'SHMTVarOpt2.f95']
SRCSFFTW2 = ['MakeGridDH2.f95', 'MakeGridDHC2.f95', 'MakeGridGLQ2.f95', 'MakeGridGLQC2.f95',
    'SHExpandDH2.f95', 'SHExpandDHC2.f95', 'SHExpandGLQ2.f95', 'SHExpandGLQC2.f95',
    'MakeGravGradGridDH2.f95', 'MakeGravGridDH2.f95', 'MakeMagGridDH2.f95']

F2PY_SHTOOLS_FILES = filter(lambda x: not x.split('\\')[-1] in SRCSLAPACK2, F2PY_SHTOOLS_FILES)
F2PY_SHTOOLS_FILES = filter(lambda x: not x.split('\\')[-1] in SRCSFFTW2, F2PY_SHTOOLS_FILES)

def configuration(parent_package='',top_path=None):
    from numpy.distutils.misc_util import Configuration
    
    config = Configuration(
        NAME,
        parent_package,
        top_path,
        version = VERSION,
        maintainer  = MAINTAINER,
        maintainer_email = MAINTAINER_EMAIL,
        description = DESCRIPTION,
        license = LICENSE,
        url = URL,
        long_description = LONG_DESCRIPTION
    )


    config.add_extension(
        name=F2PY_MODULE_NAME,
        sources=[F2PY_SIGN_FILE] + F2PY_SHTOOLS_FILES,
        libraries=['libopenblas', 'libfftw3-3'],
        include_dirs=['fftw', 'OpenBLAS/include'],
        library_dirs=['fftw', 'OpenBLAS/lib'],
        extra_compile_args=['-static', '-static-libgcc', '-static-libstdc++'],
        f2py_options=[]#'--debug-capi']
    )

    config.add_extension(
        name='_constant',
        sources=['src/PlanetsConstants.f95'],
        f2py_options=['--quiet']#'--debug-capi']
    )

    
    return config


if __name__ == "__main__":

    from numpy.distutils.core import setup
    
    setup(
        configuration=configuration,
        packages = setuptools.find_packages(),
        include_package_data = True,
        platforms = ["any"],
        requires=["numpy"],
        tests_require = ['nose',],
        test_suite='nose.collector',
        zip_safe = True,
        classifiers =classifiers
    )
