classdef ProgressDef < handle

    properties (Access = private)
        mWeight = 0
        mChildren = Progress.ProgressDef.empty
        mTotal = NaN
        mCompleted = NaN
    end

    properties (SetAccess = private)
        completion = 0
        isCompleted = false
    end

    properties (Dependent)
        hasChildren
        hasSteps
    end

    methods (Access = private)

        function changed = updateCompletion(obj)
            
            if obj.isCompleted
                newCompletion = 1;
            elseif obj.hasChildren
                weights = [obj.mChildren.mWeight];
                completions = [obj.mChildren.completion];
                weightsSum = sum(weights);
                if weightsSum == 0
                    weightsSum = 1;
                end
                newCompletion = sum(completions .* weights) ./ weightsSum;
            elseif obj.hasSteps
                newCompletion = max(obj.mCompleted, 0) ./ max(obj.mTotal, 1);
            else
                newCompletion = 0;
            end

            changed = newCompletion ~= obj.completion;
            obj.completion = newCompletion;

        end

        function ensureChild(obj, index)

            arguments
                obj
                index (1, 1) {mustBeInteger, mustBePositive}
            end

            if length(obj.mChildren) < index
                obj.mChildren(index) = Progress.ProgressDef();
            end

        end

    end

    methods (Access = {?Progress.ProgressBar})

        function changed = completeAt(obj, indices)

            arguments
                obj
                indices (:, 1) {mustBeInteger, mustBePositive}
            end

            if ~obj.isCompleted
                if isempty(indices)
                    obj.isCompleted = true;
                    obj.completion = 1;
                    obj.mChildren = Progress.ProgressDef.empty;
                    obj.mTotal = NaN;
                    obj.mCompleted = NaN;
                    changed = true;
                else
                    obj.ensureChild(indices(1));
                    changed = obj.mChildren(indices(1)).complete(indices(2:end));
                    if changed
                        changed = obj.updateCompletion();
                    end
                end
            else
                changed = false;
            end

        end
        
        function changed = stepAt(obj, indices, count)

            arguments
                obj
                indices (:, 1) {mustBeInteger, mustBePositive}
                count (1, 1) {mustBeInteger, mustBeNonnegative}
            end

            if ~obj.isCompleted && count > 0
                if isempty(indices)
                    if obj.hasChildren
                        error('Progress has children');
                    end
                    obj.mCompleted = max(obj.mCompleted + count, count);
                    changed = obj.updateCompletion();
                else
                    obj.ensureChild(indices(1));
                    changed = obj.mChildren(indices(1)).stepAt(indices(2:end), count);
                    if changed
                        changed = obj.updateCompletion();
                    end
                end
            else
                changed = false;
            end
            
        end
        
        function changed = addStepsAt(obj, indices, count)
            
            arguments
                obj
                indices (:, 1) {mustBeInteger, mustBePositive}
                count (1, 1) {mustBeInteger, mustBeNonnegative}
            end

            if ~obj.isCompleted && count > 0
                if isempty(indices)
                    if obj.hasChildren
                        error('Progress has children');
                    end
                    obj.mTotal = max(obj.mTotal + count, count);
                    changed = obj.updateCompletion();
                else
                    obj.ensureChild(indices(1));
                    changed = obj.mChildren(indices(1)).addStepsAt(indices(2:end), count);
                    if changed
                        changed = obj.updateCompletion();
                    end
                end
            else
                changed = false;
            end

        end
        
        function changed = setChildrenAt(obj, indices, startIndex, weights)

            arguments
                obj
                indices (:, 1) {mustBeInteger, mustBePositive}
                startIndex (1, 1) {mustBeInteger, mustBePositive}
                weights (:, 1) {mustBeReal, mustBePositive}
            end

            if ~obj.isCompleted && ~isempty(weights)
                if isempty(indices)
                    if obj.hasSteps
                        error('Progress has steps');
                    end
                    endIndex = startIndex + size(weights, 1) - 1;
                    obj.mChildren(endIndex).mWeight = 0;
                    weights = num2cell(weights);
                    [obj.mChildren(startIndex:endIndex).mWeight] = weights{:};
                    changed = obj.updateCompletion();
                else
                    obj.ensureChild(indices(1));
                    changed = obj.mChildren(indices(1)).setChildrenAt(indices(2:end), startIndex, weights);
                    if changed
                        changed = obj.updateCompletion();
                    end
                end
            else
                changed = false;
            end

        end

    end

    methods

        function hasChildren = get.hasChildren(obj)
            hasChildren = ~isempty(obj.mChildren);
        end

        function hasSteps = get.hasSteps(obj)
            hasSteps = ~isnan(obj.mCompleted) || ~isnan(obj.mTotal);
        end

    end

end