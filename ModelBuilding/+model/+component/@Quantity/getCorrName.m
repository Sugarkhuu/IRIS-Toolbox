function namesOfCorr = getCorrName(this, request)
% getCorrName  Get names of cross-correlation coefficients of shocks
%
% Backend IRIS function
% No help provided

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2018 IRIS Solutions Team

TYPE = @int8;

%--------------------------------------------------------------------------

indexOfShocks = this.Type==TYPE(31) | this.Type==TYPE(32);
namesOfShocks = this.Name(indexOfShocks);
ne = sum(indexOfShocks);
[row, col] = find(tril(true(ne)));

if nargin<2
    request = 1 : numel(row);
end

namesOfCorr = cell(1, numel(request));
for i = request
    name = ['corr_', namesOfShocks{col(i)}, '__', namesOfShocks{row(i)}];
    namesOfCorr{i} = name;
end

end

