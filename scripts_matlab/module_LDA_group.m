function output = module_LDA_group( datamat, split_info, Resampling_Index )
%
% =========================================================================
% MODULE_LDA_GROUP: module that performs group-level linear discriminant analysis 
% in split-half NPAIRS framework
% =========================================================================
%
%   Syntax:
%           output = module_LDA_group( datamat, split_info )
%
%
% ------------------------------------------------------------------------%
% Authors: Nathan Churchill, University of Toronto
%          email: nathan.churchill@rotman.baycrest.on.ca
%          Babak Afshin-Pour, Rotman reseach institute
%          email: bafshinpour@research.baycrest.org
% ------------------------------------------------------------------------%
% CODE_VERSION = '$Revision: 158 $';
% CODE_DATE    = '$Date: 2014-12-02 18:11:11 -0500 (Tue, 02 Dec 2014) $';
% ------------------------------------------------------------------------%

if( ~isfield(split_info{1},'drf') || isempty(split_info{1}.drf) )
    disp('LDA uses default data reduction drf=0.5');
    split_info{1}.drf = 0.5;
end

% number of subjects
N_subject = length(datamat);
% split into cell arrays
for( n=1:N_subject )
    %
    data_cond1{n} = datamat{n}(:, split_info{n}.idx_cond1);
    data_cond2{n} = datamat{n}(:, split_info{n}.idx_cond2);    
end
% run lda --> *NB cond order flipped to ensure correct sign (cond1-cond2)
results = lda_optimization_group ( data_cond2, data_cond1, split_info{1}.drf, Resampling_Index );

% optimization stats
DD       = sqrt( (1-results.R).^2 + (1-results.P).^2 );
% select PC subspace that minimizes D(P,R)
[vd id]  = min(DD);

% [Record optimal statistics + eigenimages]
%
output.metrics.R    =  results.R(id);
output.metrics.P    =  results.P(id);
output.metrics.dPR  = -vd;
% optimal eigenimage
output.images       = results.eig(:,id);

% [CV scores]
%
% CV score timeseries, from reference eigenimage

% CV score timeseries, on unit-normed rSPM eigenimage
for(is=1:N_subject) 
    %
    output.temp.CV_alt{is} = datamat{is}' * (output.images ./ sqrt(sum(output.images.^2)));    
    %
    %--- now get fractional explained variance ---
    %
    % the scaled projection
    svect = output.temp.CV_alt{is};
    % and normed projection
    uvect = svect ./ sum(svect.^2);
    % get back out the scaling factor relative to normed eig
    svar = var( svect ) ./ var( uvect );
    % total data variance
    tvar = trace( datamat{is}'* datamat{is} );
    % fraction
    output.temp.CV_alt_varfract{is} = svar ./ tvar;
end
