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
        message
        maxCliProgressReports
    end

    properties (Dependent)
        isFigureOpen
        isParallel
    end

    methods (Static)
        
        function hasParallelToolbox = hasParallelToolbox()
            hasParallelToolbox = ~isempty(which('parallel.pool.DataQueue'));
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
                end
            else
                if obj.maxCliProgressReports > 0
                    nextUpdate = 1 / obj.maxCliProgressReports + obj.mLastReportedCompletion;
                    if nextUpdate <= obj.mDef.completion
                        fprintf('%s: %.2f%\n', obj.message, obj.mDef.completion * 100);
                    end
                end
            end

            obj.mLastReportedCompletion = obj.mDef.completion;

        end

        function setupFigure(obj)

            if obj.isFigureOpen
                waitbar(obj.mDef.completion, obj.mFigure, obj.message);
            else
                obj.mFigure = waitbar(obj.mDef.completion, obj.message);
            end

        end

        function setupQueue(obj)

            obj.mQueue = parallel.pool.DataQueue();
            afterEach(obj.mQueue, @(data) obj.runSync(data{:}));
            
        end
        
        function runSync(obj, method, args)
            
            if obj.mDef.(method)(args{:})
                obj.reportUpdate();
            end

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

        function obj = ProgressBar(message, maxCliProgressReports, forceSync, forceCli)

            arguments
                message (1, 1) string = ''
                maxCliProgressReports (1, 1) {mustBeInteger, mustBeNonnegative} = 10
                forceSync (1, 1) logical = false
                forceCli (1, 1) logical = false
            end

            obj.mDef = Progress.ProgressDef();
            obj.progress = Progress.Progress(obj, []);
            obj.message = message;
            obj.maxCliProgressReports = maxCliProgressReports;
            obj.isFigureOpen = ~forceCli && Progress.ProgressBar.hasDisplay();
            obj.isParallel = ~forceSync && Progress.ProgressBar.hasParallelToolbox();

        end

        function delete(obj)
            delete(obj.mFigure);
            delete(obj.mQueue);
            obj.mQueue = false;
        end

        function set.message(obj, message)

            arguments
                obj
                message (1, 1) string
            end

            obj.message = message;
            if obj.isFigureOpen
                obj.setupFigure();
            end

        end

        function set.maxCliProgressReports(obj, maxCliProgressReports)

            arguments
                obj
                maxCliProgressReports (1, 1) {mustBeInteger, mustBeNonnegative}
            end

            obj.maxCliProgressReports = maxCliProgressReports;

        end

        function set.isFigureOpen(obj, isFigureOpen)

            arguments
                obj
                isFigureOpen (1, 1) logical
            end

            if isFigureOpen ~= obj.isFigureOpen
                if isFigureOpen
                    if ~Progress.ProgressBar.hasDisplay()
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
                obj
                isParallel (1, 1) logical
            end
            
            if isParallel ~= obj.isParallel
                if isParallel
                    if ~Progress.ProgressBar.hasParallelToolbox()
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
            isFigureOpen = ishandle(obj.mFigure);
        end

        function isParallel = get.isParallel(obj)
            isParallel = obj.mQueue ~= false;
        end

    end

    methods (Access = {?Progress.Progress})

        function completeAt(obj, indices)

            arguments
                obj
                indices (:, 1) {mustBeInteger, mustBePositive}
            end

            obj.run('completeAt', {indices});
            
        end
        
        function stepAt(obj, indices, count)
            
            arguments
                obj
                indices (:, 1) {mustBeInteger, mustBePositive}
                count (1, 1) {mustBeInteger, mustBeNonnegative}
            end
            
            obj.run('stepAt', {indices, count});
            
        end
        
        function addStepsAt(obj, indices, count)
            
            arguments
                obj
                indices (:, 1) {mustBeInteger, mustBePositive}
                count (1, 1) {mustBeInteger, mustBeNonnegative}
            end
            
            obj.run('addStepsAt', {indices, count});
            
        end
        
        function setChildrenAt(obj, indices, startIndex, weights)
            
            arguments
                obj
                indices (:, 1) {mustBeInteger, mustBePositive}
                startIndex (1, 1) {mustBeInteger, mustBePositive}
                weights (:, 1) {mustBeReal, mustBePositive}
            end

            obj.run('setChildrenAt', {indices, startIndex, weights});
            
        end

    end

end