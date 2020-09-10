classdef Progress

    properties (Access = private)
        mIndices
        mOwner
    end

    methods (Access = {?MProgress.ProgressBar})
        
        function obj = Progress(owner, indices)
            
            arguments
                owner (1, 1) MProgress.ProgressBar
                indices (:, 1) {mustBeInteger, mustBePositive}
            end

            obj.mOwner = owner;
            obj.mIndices = indices;

        end

    end

    methods 

        function complete(obj)

            arguments
                obj MProgress.Progress {MProgress.mustBeScalarOrEmpty}
            end

            if isempty(obj)
                return
            end

            obj.mOwner.completeAt(obj.mIndices);

        end

        function step(obj, count)
            
            arguments
                obj MProgress.Progress {MProgress.mustBeScalarOrEmpty}
                count (1, 1) {mustBeInteger, mustBeNonnegative} = 1
            end
            
            if isempty(obj) || count < 1
                return
            end

            obj.mOwner.stepAt(obj.mIndices, count);

        end

        function addSteps(obj, count)

            arguments
                obj MProgress.Progress {MProgress.mustBeScalarOrEmpty}
                count (1, 1) {mustBeInteger, mustBeNonnegative}
            end

            if isempty(obj) || count < 1
                return
            end

            obj.mOwner.addStepsAt(obj.mIndices, count);

        end

        function varargout = setChildren(obj, weights, startIndex)

            arguments
                obj MProgress.Progress {MProgress.mustBeScalarOrEmpty}
                weights (:, 1) {mustBeReal, mustBeNonnegative} 
                startIndex (1, 1) {mustBeInteger, mustBePositive} = 1
            end

            count = size(weights, 1);
            if count > 0 && ~isempty(obj)
                obj.mOwner.setChildrenAt(obj.mIndices, startIndex, weights);
                for i = startIndex : startIndex + count - 1
                    children(i, 1) = MProgress.Progress(obj.mOwner, vertcat(obj.mIndices, i));
                end
            else
                children = MProgress.Progress.empty(count, 0);
            end

            if nargout == count
                varargout = num2cell(children);
                if isempty(children)
                    varargout(1:count) = {MProgress.Progress.empty};
                end
            else
                varargout{1} = children;
            end
            
        end

    end

end

