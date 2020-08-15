classdef Progress

    properties (Access = private)
        mIndices
        mOwner
    end

    methods (Access = {?Progress.ProgressBar})
        
        function obj = Progress(owner, indices)
            
            arguments
                owner (1, 1) Progress.ProgressBar
                indices (:, 1) {mustBeInteger, mustBePositive}
            end

            obj.mOwner = owner;
            obj.mIndices = indices;

        end

    end

    methods 

        function complete(obj)

            if isempty(obj)
                return
            end

            obj.mOwner.completeAt(obj.mIndices);

        end

        function step(obj, count)
            
            arguments
                obj
                count (1, 1) {mustBeInteger, mustBePositive} = 1
            end
            
            if isempty(obj)
                return
            end

            obj.mOwner.stepAt(obj.mIndices, count);

        end

        function addSteps(obj, count)

            arguments
                obj
                count (1, 1) {mustBeInteger, mustBePositive}
            end

            if isempty(obj)
                return
            end

            obj.mOwner.addStepsAt(obj.mIndices, count);

        end

        function children = setChildren(obj, weights, startIndex)

            arguments
                obj
                weights (:, 1) {mustBeReal, mustBeNonnegative}
                startIndex (1, 1) {mustBeInteger, mustBePositive} = 1
            end

            if isempty(obj)
                return
            end

            obj.mOwner.setChildrenAt(obj.mIndices, startIndex, weights);
            count = size(weights, 1);
            for i = startIndex:startIndex + count
                children(i, 1) = CVP.Utils.Progress.Progress(obj.mOwner, vertcat(obj.mIndices, i));
            end
            
        end

    end

end