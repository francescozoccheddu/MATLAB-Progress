function mustBeScalarOrEmpty(argument)

    if ~isempty(argument) && ~isscalar(argument)
        error('Argument must be scalar or empty.');
    end

end