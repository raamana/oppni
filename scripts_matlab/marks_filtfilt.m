## Copyright (C) 1999 Paul Kienzle <pkienzle@users.sf.net>
## Copyright (C) 2007 Francesco Potortì <pot@gnu.org>
## Copyright (C) 2008 Luca Citi <lciti@essex.ac.uk>
##
## Modified version for perfomance profiling and testing
## by Mark Prati <mprati@research.baycrest.org>
##  
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING. If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{y} =} filtfilt (@var{b}, @var{a}, @var{x})
##
## Forward and reverse filter the signal. This corrects for phase
## distortion introduced by a one-pass filter, though it does square the
## magnitude response in the process. That's the theory at least.  In
## practice the phase correction is not perfect, and magnitude response
## is distorted, particularly in the stop band.
##
## Example
## @example
## @group
## [b, a]=butter(3, 0.1);                  # 5 Hz low-pass filter
## t = 0:0.01:1.0;                         # 1 second sample
## x=sin(2*pi*t*2.3)+0.25*randn(size(t));  # 2.3 Hz sinusoid+noise
## y = filtfilt(b,a,x); z = filter(b,a,x); # apply filter
## plot(t,x,';data;',t,y,';filtfilt;',t,z,';filter;')
## @end group
## @end example
## @end deftypefn

## FIXME: My version seems to have similar quality to matlab,
##        but both are pretty bad.  They do remove gross lag errors, though.

function y = marks_filtfilt(b, a, x)
  
  profile on  
  disp("DEBUG - Starting marks_filtfilt");
  if (nargin != 3)
    print_usage;
  endif
  
  lx = size(x,1);
  rotate = (lx==1);
  if rotate,                    # a row vector
    x = x(:);                   # make it a column vector
  endif
  
  a = a(:).';
  b = b(:).';
  lb = length(b);
  la = length(a);
  n = max(lb, la);
  lrefl = 3 * (n - 1);
  if la < n, a(n) = 0; endif
  if lb < n, b(n) = 0; endif

  ## Compute a the initial state taking inspiration from
  ## Likhterov & Kopeika, 2003. "Hardware-efficient technique for
  ##     minimizing startup transients in Direct Form II digital filters"
  kdc = sum(b) / sum(a);
  if (abs(kdc) < inf) # neither NaN nor +/- Inf
    si = fliplr(cumsum(fliplr(b - kdc * a)));
  else
    si = zeros(size(a)); # fall back to zero initialization
  endif
  si(1) = [];

  ## This loop generally executes tens of thousands of times.
  ## For optimization all repetitivly redundent calculation should be moved ouside the loop body.
  ## Mods by Mark Prati
  ###########################
  sx2 = size(x,2);
  lrefl1 = lrefl + 1;
  lxlrefl = lx + lrefl;
  printf("DEBUG - lx = %d, la = %d, lb = %d, n = %d, lrefl = %d, sx2 = %d\n",lx,la,lb,n,lrefl,sx2);  
  # Optimize by pre-allocating matrix memory 
  y = zeros(lx,sx2);
  ###########################

  for (c = 1:sx2) # filter all columns, one by one
    v = [2*x(1,c)-x((lrefl1):-1:2,c); x(:,c); 2*x(end,c)-x((end-1):-1:end-lrefl,c)]; # a column vector
    v = filter(b,a,v,si*v(1));                   # forward filter
    v = flipud(filter(b,a,flipud(v),si*v(end))); # reverse filter
    y(:,c) = v((lrefl1):(lxlrefl));
  endfor
  printf("DEBUG - filtfilt loop completed %d iterations\n", c) 
  if (rotate)                   # x was a row vector
    y = rot90(y);               # rotate it back
  endif
  
  profile off;
  pData = profile("info")
  disp('Profile Dump after filtfilt ====');
  profshow(pData,10);
  profile clear;
  
endfunction

%!error filtfilt ();

%!error filtfilt (1, 2, 3, 4);

%!test
%! randn('state',0);
%! r = randn(1,200);
%! [b,a] = butter(10, [.2, .25]);
%! yfb = filtfilt(b, a, r);
%! assert (size(r), size(yfb));
%! assert (mean(abs(yfb)) < 1e3);
%! assert (mean(abs(yfb)) < mean(abs(r)));
%! ybf = fliplr(filtfilt(b, a, fliplr(r)));
%! assert (mean(abs(ybf)) < 1e3);
%! assert (mean(abs(ybf)) < mean(abs(r)));

%!test
%! randn('state',0);
%! r = randn(1,1000);
%! s = 10 * sin(pi * 4e-2 * (1:length(r)));
%! [b,a] = cheby1(2, .5, [4e-4 8e-2]);
%! y = filtfilt(b, a, r+s);
%! assert (size(r), size(y));
%! assert (mean(abs(y)) < 1e3);
%! assert (corr(s(250:750), y(250:750)) > .95)
%! [b,a] = butter(2, [4e-4 8e-2]);
%! yb = filtfilt(b, a, r+s);
%! assert (mean(abs(yb)) < 1e3);
%! assert (corr(y, yb) > .99)

%!test
%! randn('state',0);
%! r = randn(1,1000);
%! s = 10 * sin(pi * 4e-2 * (1:length(r)));
%! [b,a] = butter(2, [4e-4 8e-2]);
%! y = filtfilt(b, a, [r.' s.']);
%! yr = filtfilt(b, a, r);
%! ys = filtfilt(b, a, s);
%! assert (y, [yr.' ys.']);
%! y2 = filtfilt(b.', a.', [r.' s.']);
%! assert (y, y2);
