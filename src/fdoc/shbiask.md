# SHBiasK

Calculate the multitaper (cross-)power spectrum expectation of function localized by spherical cap windows.

# Usage

call SHBiasK (`tapers`, `lwin`, `numk`, `incspectra`, `ldata`, `outcspectra`, `taper_wt`, `save_cg`)

# Parameters

`tapers` : input, real\*8, dimension (`lwin`+1, `numk`)
:   The spherical coefficients of the localizing windows. Each column corresponds to the non-zero coefficients of a single angular order. Since all that is important is the power spectrum of each window, the exact angular order is not important. These are generated by a call to `SHReturnTapers` or `SHReturnTapersM`.

`lwin` : input, integer
:   The spherical harmonic bandwidth of the localizing windows.

`numk` : input, integer
:   The number of localizing windows to use. Only the first `numk` columns of `tapers` will be employed, which corresponds to the best-concentrated localizing windows.
	
`incspectra` : input, real\*8, dimension (`ldata`+1)
:   The global unwindowed power spectrum.

`ldata` : input, integer
:   The maximum degree of the global unwindowed power spectrum.

`outcspectra` : output, real\*8, dimension (`ldata`+`lwin`+1)
:   The expectation of the multitaper localized power spectrum.

`taper_wt` : input, optional, real\*8, dimension (`numk`)
:   The weights to apply to each individual windowed specral estimate. The weights must sum to unity and are obtained from `SHMTVarOpt`.

`save_cg` : input, optional, integer, default = 0
:   If set equal to 1, the Clebsch-Gordon coefficients will be precomputed and saved for future use (if `lwin` or `ldata` change, this will be recomputed). To deallocate the saved memory, set this parameter equal to 1. If set equal to 0 (default), the Clebsch-Gordon coefficients will be recomputed for each call.

# Description

`SHBiasK` will calculate the multitaper (cross-)power spectrum expectation of a function multiplied by the `numk` best-concentrated localizing windows. This is given by equation 36 of Wieczorek and Simons (2005) (see also eq. 2.11 of Wieczorek and Simons 2007). In contrast to `SHBias`, which takes as input the power spectrum of a single localizing window, this routine expects as input a matrix containing the spherical harmonic coefficients of the localizing windows. These can be generated by a call to `SHReturnTapers` or `SHReturnTapersM`. The maximum calculated degree of the windowed power spectrum expectation corresponds to the smaller of (`ldata`+`lwin`) and `size(outcspectra)-1`. It is assumed implicitly that the power spectrum of `inspectrum` is zero beyond degree `ldata`. Note that this routine will only work when the window coefficients are non-zero for a single angular order.

The default is to apply equal weights to each individual windowed estimate of the spectrum, but this can be modified by specifying the weights in the optional argument `taper_wt`. The weights must sum to unity. If this routine is to be called several times using the same values of `lwin` and `ldata`, then the Clebsch-Gordon coefficients can be precomputed and saved by setting the optional parameter `save_cg` equal to 1.

# References

Wieczorek, M. A. and F. J. Simons, Minimum-variance multitaper spectral estimation on the sphere, J. Fourier Anal. Appl., 13, 665-692, doi:10.1007/s00041-006-6904-1, 2007.

Simons, F. J., F. A. Dahlen and M. A. Wieczorek, Spatiospectral concentration on a sphere, SIAM Review, 48, 504-536, doi:10.1137/S0036144504445765, 2006. 

Wieczorek, M. A. and F. J. Simons, Localized spectral analysis on the sphere, 
Geophys. J. Int., 162, 655-675, doi:10.1111/j.1365-246X.2005.02687.x, 2005.

# See also

[shbias](shbias.html), [shmtvaropt](shmtvaropt.html), [shreturntapers](shreturntapers.html), [shreturntapersm](shreturntapersm.html), [shmtvaropt](shmtvaropt.html), [shbiasadmitcorr](shbiasadmitcorr.html), [shmtcouplingmatrix](shmtcouplingmatrix.html)
