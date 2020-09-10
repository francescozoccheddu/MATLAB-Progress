classdef ProgressBar < handle

    properties (Access = private)
        mDef
        mQueue = false
        mFigure = false
        mLastReportedCompletion = 0
    end

    properties (SetAccess = private)
        progress
    end

    properties
        message = 'Progress'
        minCliReportMargin
    end

    properties (Dependent)
        isFigureOpen
        isParallel
    end

    methods (Static)
        
        function hasParallelToolbox = hasParallelToolbox()
            hasParallelToolbox = ~isempty(which('parallel.pool.DataQueue'));
        end

        function hasParallelPool = hasParallelPool()
            hasParallelPool =  MProgress.ProgressBar.hasParallelToolbox() && ~isempty(gcp('nocreate'));
        end
        
        function hasDisplay = hasDisplay()
            hasDisplay = ~isequal(get(0, 'ScreenSize'), [1 1 1 1]);
        end

    end

    methods (Access = private)

        function reportUpdate(obj)

            if obj.isFigureOpen
                if obj.mDef.completion ~= obj.mLastReportedCompletion
                    obj.setupFigure();
                    obj.mLastReportedCompletion = obj.mDef.completion;
                end
            else
                if obj.mDef.completion > obj.mLastReportedCompletion + obj.minCliReportMargin
                    obj.reportProgress(true);
                    obj.mLastReportedCompletion = obj.mDef.completion;
                end
            end

        end

        function setupFigure(obj)

            content = sprintf('%s (%d%%)', obj.message, round(obj.mDef.completion * 100));
            if obj.isFigureOpen
                waitbar(obj.mDef.completion, obj.mFigure, content);
                if ishandle(obj.mFigure)
                    obj.mFigure.Name = obj.message;
                end
            else
                obj.mFigure = waitbar(obj.mDef.completion, content, 'Name', obj.message);
            end

        end

        function setupQueue(obj)

            obj.mQueue = parallel.pool.DataQueue();
            afterEach(obj.mQueue, @(data) obj.runSync(data{:}));
            
        end
        
        function runSync(obj, method, args)
            
            obj.mDef.(method)(args{:});
            obj.reportUpdate();

        end

        function run(obj, method, args)
            
            if obj.isParallel
                send(obj.mQueue, {method, args});
            else
                obj.runSync(method, args);
            end

        end

    end

    methods 

        function obj = ProgressBar(message, minCliReportMargin, forceSync, forceCli)

            arguments
                message (1, 1) string = 'Progress'
                minCliReportMargin (1, 1) {mustBeReal, mustBeNonnegative, mustBeLessThanOrEqual(minCliReportMargin, 1)} = 1 / 10
                forceSync (1, 1) logical = false
                forceCli (1, 1) logical = false
            end

            obj.mDef = MProgress.ProgressDef();
            obj.progress = MProgress.Progress(obj, []);
            obj.minCliReportMargin = minCliReportMargin;
            obj.isFigureOpen = ~forceCli && MProgress.ProgressBar.hasDisplay();
            obj.isParallel = ~forceSync && MProgress.ProgressBar.hasParallelToolbox();
            obj.message = message;

        end

        function delete(obj)

            arguments
                obj (1, 1) MProgress.ProgressBar
            end

            obj.isFigureOpen = false;
            obj.isParallel = false;
            
        end

        function reportProgress(obj, forceCli)

            arguments
                obj (1, 1) MProgress.ProgressBar
                forceCli (1, 1) logical = false
            end

            if forceCli || ~obj.isFigureOpen
                fprintf('(%s) %s: %.2f%%\n', datestr(now,'HH:MM:SS'), obj.message, obj.mDef.completion * 100);
                obj.mLastReportedCompletion = obj.mDef.completion;
            end

        end

        function set.message(obj, message)

            arguments
                obj (1, 1) MProgress.ProgressBar
                message (1, 1) string
            end

            obj.message = message;
            if obj.isFigureOpen
                obj.setupFigure();
            else
                obj.reportProgress(true);
            end

        end

        function set.minCliReportMargin(obj, minCliReportMargin)

            arguments
                obj (1, 1) MProgress.ProgressBar
                minCliReportMargin (1, 1) {mustBeReal, mustBeNonnegative, mustBeLessThanOrEqual(minCliReportMargin, 1)}
            end

            obj.minCliReportMargin = minCliReportMargin;

        end

        function set.isFigureOpen(obj, isFigureOpen)

            arguments
                obj (1, 1) MProgress.ProgressBar
                isFigureOpen (1, 1) logical
            end

            if isFigureOpen ~= obj.isFigureOpen
                if isFigureOpen
                    if ~MProgress.ProgressBar.hasDisplay()
                        error('No display');
                    end
                    obj.setupFigure();
                else
                    delete(obj.mFigure);
                end
            end

        end

        function set.isParallel(obj, isParallel)

            arguments
                obj (1, 1) MProgress.ProgressBar
                isParallel (1, 1) logical
            end
            
            if isParallel ~= obj.isParallel
                if isParallel
                    if ~MProgress.ProgressBar.hasParallelToolbox()
                        error('No parallel toolbox');
                    end
                    obj.setupQueue();
                else
                    delete(obj.mQueue);
                    obj.mQueue = false;
                end
            end

        end

        function isFigureOpen = get.isFigureOpen(obj)

            arguments
                obj (1, 1) MProgress.ProgressBar
            end

            isFigureOpen = ishandle(obj.mFigure);

        end

        function isParallel = get.isParallel(obj)

            arguments
                obj (1, 1) MProgress.ProgressBar
            end

            isParallel = obj.mQueue ~= false;

        end

    end

    methods (Access = {?MProgress.Progress})

        function completeAt(obj, indices)

            arguments
                obj (1, 1) MProgress.ProgressBar
                indices (:, 1) {mustBeInteger, mustBePositive}
            end

            obj.run('completeAt', {indices});
            
        end
        
        function stepAt(obj, indices, count)
            
            arguments
                obj (1, 1) MProgress.ProgressBar
                indices (:, 1) {mustBeInteger, mustBePositive}
                count (1, 1) {mustBeInteger, mustBeNonnegative}
            end
            
            obj.run('stepAt', {indices, count});
            
        end
        
        function addStepsAt(obj, indices, count)
            
            arguments
                obj (1, 1) MProgress.ProgressBar
                indices (:, 1) {mustBeInteger, mustBePositive}
                count (1, 1) {mustBeInteger, mustBeNonnegative}
            end
            
            obj.run('addStepsAt', {indices, count});
            
        end
        
        function setChildrenAt(obj, indices, startIndex, weights)
            
            arguments
                obj (1, 1) MProgress.ProgressBar
                indices (:, 1) {mustBeInteger, mustBePositive}
                startIndex (1, 1) {mustBeInteger, mustBePositive}
                weights (:, 1) {mustBeReal, mustBePositive}
            end

            obj.run('setChildrenAt', {indices, startIndex, weights});
            
        end

    end

end