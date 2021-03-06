classdef InputParser < inputParser
    properties
        PrimaryParameterNames = cell.empty(1, 0)
        Options = struct( )
        Aliases = struct( )

        HasDateOptions = false
        HasDeviationOptions = false
        HasSwapOptions = false
        HasOptionalRangeStartEnd = false
        HasStartEndOptions = false
    end


    properties (Dependent)
        UnmatchedInCell
        UsingDefaultsInStruct
    end


    methods
        function this = InputParser(functionName)
            this = this@inputParser( );
            this.CaseSensitive = false;
            if nargin>0
                this.FunctionName = char(functionName);
            end
        end%


        function parse(this, varargin)
            ix = cellfun(@(x) ischar(x) || (isa(x, 'string') && isscalar(x)), varargin);
            varargin(ix) = cellfun(@(x) regexprep(x, '=$', ''), varargin(ix), 'UniformOutput', false);
            parse@inputParser(this, varargin{:});
            for i = 1 : numel(this.PrimaryParameterNames)
                ithName = this.PrimaryParameterNames{i};
                this.Options.(ithName) = this.Results.(ithName);
            end
            listOfAliases = fieldnames(this.Aliases);
            for i = 1 : numel(listOfAliases)
                ithAlias = listOfAliases{i};
                ithPrimaryName = this.Aliases.(ithAlias);
                if any(strcmp(ithPrimaryName, this.UsingDefaults)) ...
                    && ~any(strcmp(ithAlias, this.UsingDefaults))
                    this.Options.(ithPrimaryName) = this.Results.(ithAlias);
                end
            end
            if this.HasDateOptions
                resolveDateOptions(this);
            end
            if this.HasDeviationOptions
                resolveDeviationOptions(this);
            end
            if this.HasOptionalRangeStartEnd
                resolveOptionalRangeStartEnd(this);
            end
            if this.HasStartEndOptions
                resolveStartEndOptions(this);
            end
        end%


        function addParameter(this, name, varargin)
            if ischar(name) || (isa(name, 'string') && numel(name)==1)
                addParameter@inputParser(this, name, varargin{:});
                this.PrimaryParameterNames{end+1} = name;
                return
            end
            if isa(name, 'string')
                name = cellstr(name);
            end
            primaryName = name{1};
            addParameter@inputParser(this, primaryName, varargin{:});
            this.PrimaryParameterNames{end+1} = primaryName;
            for i = 2 : numel(name)
                ithName = name{i};
                this.Aliases.(ithName) = primaryName;
                addParameter@inputParser(this, ithName, varargin{:});
            end
        end%


        function unmatched = get.UnmatchedInCell(this)
            names = fieldnames(this.Unmatched);
            numUnmatched = numel(names);
            unmatched = cell(2, numUnmatched);
            for i = 1 : numUnmatched
                unmatched{1, i} = names{i};
                unmatched{2, i} = this.Unmatched.(names{i});
            end
            unmatched = unmatched(:);
        end%


        function usingDefaults = get.UsingDefaultsInStruct(this)
            usingDefaults = struct( );
            for i = 1 : numel(this.PrimaryParameterNames)
                ithName = this.PrimaryParameterNames{i};
                usingDefaults.(ithName) = any(strcmp(this.UsingDefaults, ithName));
            end
        end%


        function addDateOptions(this)
            this.addParameter('DateFormat', @config, @iris.Configuration.validateDateFormat);
            this.addParameter({'FreqLetters', 'FreqLetter'}, @config, @iris.Configuration.validateFreqLetters);
            this.addParameter({'Months', 'Month'}, @config, @iris.Configuration.validateMonths);
            this.addParameter({'ConversionMonth', 'StandInMonth'}, @config, @iris.Configuration.validateConversionMonth);
            this.addParameter('WDay', @config, @iris.Configuration.validateWDay);
            this.HasDateOptions = true;
        end%


        function addDeviationOptions(this, deviationDefault)
            this.addParameter({'Deviation', 'Deviations'}, deviationDefault, @(x) isequal(x, true) || isequal(x, false));
            this.addParameter({'DTrends', 'DTrend'}, @auto, @(x) isequal(x, @auto) || isequal(x, true) || isequal(x, false));
            this.HasDeviationOptions = true;
        end%


        function addBaseYearOption(this)
            this.addParameter('BaseYear', @config, @iris.Configuration.validateBaseYear);
        end%


        function addUserDataOption(this)
            this.addParameter('UserData', double.empty(1, 0));
        end%


        function addSwapOptions(this)
            this.addParameter('Exogenize', cell.empty(1, 0), @(x) isempty(x) || ischar(x) || iscellstr(x) || isa(x, 'string') || isequal(x, @auto));
            this.addParameter('Endogenize', cell.empty(1, 0), @(x) isempty(x) || ischar(x) || iscellstr(x) || isa(x, 'string') || isequal(x, @auto));
            this.HasSwapOptions = true;
        end%


        function addOptionalRangeStartEnd(this)
            this.addOptional('Range', @auto, @(x) isequal(x, @auto) || isequal(x, Inf) || DateWrapper.validateRangeInput(x));
            this.addStartEndOptions( );
            this.HasOptionalRangeStartEnd = true;
        end%


        function addStartEndOptions(this)
            this.addParameter('Start', -Inf, @(x) isequal(x, -Inf) || DateWrapper.validateDateInput(x));
            this.addParameter('End', Inf, @(x) isequal(x, Inf) || DateWrapper.validateDateInput(x));
            this.HasStartEndOptions = true;
        end%


        function resolveDateOptions(this, isPlot)
            if nargin<2
                isPlot = false;
            end

            configStruct = iris.get( );

            if isequal(this.Options.DateFormat, @config)
                if ~isPlot
                    this.Options.DateFormat = configStruct.DateFormat;
                else
                    this.Options.DateFormat = configStruct.plotDateFormat;
                end
            end

            if isequal(this.Options.FreqLetters, @config)
                this.Options.FreqLetters = configStruct.FreqLetters;
            end

            if isequal(this.Options.Months, @config)
                this.Options.Months = configStruct.Months;
            end

            if isequal(this.Options.ConversionMonth, @config)
                this.Options.ConversionMonth = configStruct.ConversionMonth;
            end

            if isequal(this.Options.WDay, @config)
                this.Options.WDay = configStruct.WDay;
            end
        end%


        function resolveDeviationOptions(this)
            if isequal(this.Options.DTrends, @auto)
                this.Options.DTrends = ~this.Options.Deviation;
            end
        end%


        function resolveOptionalRangeStartEnd(this)
            if isequal(this.Results.Range, @auto)
                return
            end
            if isequal(this.Results.Range, Inf)
                this.Options.Start = -Inf;
                this.Options.End = Inf;
                return
            end
            this.Options.Start = this.Results.Range(1);
            this.Options.End = this.Results.Range(end);
        end


        function resolveStartEndOptions(this)
            if isfield(this.Results, 'InputSeries')
                if ~validateDateOrInf(this.Results.InputSeries, this.Options.Start)
                    throw( exception.Base('InputParser:InvalidStartOption', 'error') );
                end
                if ~validateDateOrInf(this.Results.InputSeries, this.Options.End)
                    throw( exception.Base('InputParser:InvalidEndOption', 'error') );
                end
            end
            this.Options.SerialOfStart = DateWrapper.getSerialFromNumeric(this.Options.Start);
            this.Options.SerialOfEnd = DateWrapper.getSerialFromNumeric(this.Options.End);
        end%
    end
end
