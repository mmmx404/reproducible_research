function [ D1 ] = fx_mssa(D,flow,fhigh,dt,N,verb)
%  FX_MSSA: F-X domain multichannel singular spectrum analysis (MSSA)
%
%  IN   D:   	intput data 
%       flow:   processing frequency range (lower)
%       fhigh:  processing frequency range (higher)
%       dt:     temporal sampling interval
%       N:      number of singular value to be preserved
%       verb:   verbosity flag (default: 0)
%      
%  OUT  D1:  	output data
% 
%  Copyright (C) 2013 The University of Texas at Austin
%  Copyright (C) 2013 Yangkang Chen
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published
%  by the Free Software Foundation, either version 3 of the License, or
%  any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details: http://www.gnu.org/licenses/
%  
% References:
% Chen, Y., D. Zhang, Z. Jin, X. Chen, S. Zu, W. Huang, and S. Gan, 2016, Simultaneous denoising and reconstruction of 5D seismic data via damped rank-reduction method, Geophysical Journal International, 206, 1695-1717.
% Bai et al., 2020, Seismic signal enhancement based on the lowrank methods, Geophysical Prospecting, 68, 2783-2807.
% Chen et al., 2020, Five-dimensional seismic data reconstruction using the optimally damped rank-reduction method, Geophysical Journal International, 222, 1824-1845.
% Chen, Y., W. Huang, D. Zhang, W. Chen, 2016, An open-source matlab code package for improved rank-reduction 3D seismic data denoising and reconstruction, Computers & Geosciences, 95, 59-66.
% Huang, W., R. Wang, Y. Chen, H. Li, and S. Gan, 2016, Damped multichannel singular spectrum analysis for 3D random noise attenuation, Geophysics, 81, V261-V270.
% Chen et al., 2017, Preserving the discontinuities in least-squares reverse time migration of simultaneous-source data, Geophysics, 82, S185-S196.
% Chen et al., 2019, Obtaining free USArray data by multi-dimensional seismic reconstruction, Nature Communications, 10:4434.

if nargin==0
 error('Input data must be provided!');
end

if nargin==1
 flow=1;
 fhigh=124;
 dt=0.004;
 N=1;
 verb=0;
end;


[sample,trace ]=size(D);
D1=zeros(sample,trace);

nf=2^nextpow2(sample);

% Transform into F-X domain
DATA_FX=fft(D,nf,1);
DATA_FX0=zeros(nf,trace);

% First and last samples of the DFT.
ilow  = floor(flow*dt*nf)+1;

if ilow<1;
    ilow=1;
end;

ihigh = floor(fhigh*dt*nf)+1;

if ihigh > floor(nf/2)+1;
    ihigh=floor(nf/2)+1;
end

% F-X domain emd
for k=ilow:ihigh
   
    r=hankel(DATA_FX(k,1:round((trace+1)/2)),[DATA_FX(k,round((trace+1)/2):trace)]);
    [U,D,V]=svd(r);
    D1=D; % the size of D1 is round((trace+1)/2)*trace+1-round((trace+1)/2)
    for j=N+1:trace+1-round((trace+1)/2)
        D1(j,j)=0;
    end
    r1=U*D1*V';    
    DATA_FX0(k,:)=[r1(:,1).',r1(round((trace+1)/2),2:trace+1-round((trace+1)/2))];

    if(mod(k,5)==0 && verb==1)
        fprintf( 'F %d is done!\n\n',k);
    end
end

% Honor symmetries
for k=nf/2+2:nf
    DATA_FX0(k,:) = conj(DATA_FX0(nf-k+2,:));
end

% Back to TX (the output)
D1=real(ifft(DATA_FX0,[],1));
D1=D1(1:sample,:);

return