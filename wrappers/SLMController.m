function slm = SLMController(MAX_HOLOGRAMS, width, height, x0, y0, dll_path)
    % SLMController: MATLAB wrapper for the slmctrl shared library.
    %   slm = SLMController(MAX_HOLOGRAMS, width, height, x0, y0)
    %   slm = SLMController(..., dll_path)
    %
    % Inputs
    %   MAX_HOLOGRAMS : maximum number of holograms handled by the device
    %   width         : SLM width in pixels
    %   height        : SLM height in pixels
    %   x0, y0        : Base position for the SLM window
    %   dll_path      : (optional) path to the slmctrl DLL (defaults to 'slmctrl.dll')
    %
    % The returned struct exposes function handles mirroring the Python wrapper
    % for a consistent developer experience across languages.

    arguments
        MAX_HOLOGRAMS (1,1) double {mustBePositive, mustBeInteger}
        width (1,1) double {mustBePositive, mustBeInteger}
        height (1,1) double {mustBePositive, mustBeInteger}
        x0 (1,1) double {mustBeInteger}
        y0 (1,1) double {mustBeInteger}
        dll_path (1,1) string = "slmctrl.dll"
    end

    slm.MAX_HOLOGRAMS = uint32(MAX_HOLOGRAMS);
    slm.N = int32(width);
    slm.M = int32(height);
    slm.x0 = int32(x0);
    slm.y0 = int32(y0);
    slm.dllPath = dll_path;

    % Load the shared library if required
    if ~libisloaded('slmctrl')
        loadlibrary(slm.dllPath, 'slmctrl.h');
    end

    % Expose public API mirroring the Python controller
    slm.StartUI = @StartUI;
    slm.InsertHolograms = @InsertHolograms;
    slm.SetHologramSequence = @SetHologramSequence;
    slm.StartSequence = @StartSequence;
    slm.StopUI = @StopUI;
    slm.SetHologram = @SetHologram;
    slm.ResetUI = @ResetUI;
    slm.Cleanup = @cleanup;

    function status = StartUI(show_debug_window, windowed)
        if nargin < 1 || isempty(show_debug_window)
            show_debug_window = false;
        end
        if nargin < 2 || isempty(windowed)
            windowed = false;
        end

        validateattributes(show_debug_window, {'logical', 'numeric'}, {'scalar'});
        validateattributes(windowed, {'logical', 'numeric'}, {'scalar'});

        show_debug_window = logical(show_debug_window);
        windowed = logical(windowed);

        calllib('slmctrl', 'SetSLMWindowPos', slm.N, slm.M, slm.x0, slm.y0, windowed);
        calllib('slmctrl', 'StartUI', slm.MAX_HOLOGRAMS, show_debug_window);
    end

    function res = InsertHolograms(holograms, offset)
        if ndims(holograms) == 2
            holograms = reshape(holograms, size(holograms, 1), size(holograms, 2), 1);
        end

        validateattributes(holograms, {'uint8'}, {'3d'});
        validateattributes(offset, {'numeric'}, {'scalar', 'nonnegative', 'integer'});

        num_frames = size(holograms, 3);
        res = calllib('slmctrl', 'InsertSLMHologram', libpointer('uint8Ptr', holograms), uint64(num_frames), uint64(offset));
    end

    function SetHologramSequence(sequence)
        validateattributes(sequence, {'numeric'}, {'vector', 'integer', 'nonnegative'});
        sequence = uint64(sequence(:));
        calllib('slmctrl', 'SetHologramSequence', libpointer('uint64Ptr', sequence), uint64(numel(sequence)));
    end

    function res = StartSequence(holograms_to_display)
        validateattributes(holograms_to_display, {'numeric'}, {'scalar', 'positive', 'integer'});
        res = calllib('slmctrl', 'StartSequence', int32(holograms_to_display));
    end

    function StopUI()
        calllib('slmctrl', 'StopUI');
    end

    function res = SetHologram(hologram_index)
        validateattributes(hologram_index, {'numeric'}, {'scalar', 'nonnegative', 'integer'});
        res = calllib('slmctrl', 'SetSLMHologram', uint64(hologram_index));
    end

    function ResetUI()
        calllib('slmctrl', 'ResetUI');
    end

    function cleanup()
        calllib('slmctrl', 'StopUI');
        if libisloaded('slmctrl')
            unloadlibrary('slmctrl');
        end
    end
end