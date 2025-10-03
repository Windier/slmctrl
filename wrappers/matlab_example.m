clearvars;

addpath('..');
addpath('../bin');

%% Controller configuration (mirrors python_example.ipynb)
MAX_HOLOGRAMS = 400;   % Maximum hologram slots in device memory
N = 1920;               % SLM width  (pixels)
M = 1080;               % SLM height (pixels)
x0 = 2560;                % Base X position for the SLM window
y0 = 0;                % Base Y position for the SLM window
dll_path = fullfile('..', 'bin', 'slmctrl.dll');

slm = SLMController(MAX_HOLOGRAMS, N, M, x0, y0, dll_path);

%% Start the UI in windowed mode without the debug viewport
debug_window = true;
windowed = false;
slm.StartUI(debug_window, windowed);

%% Test 1: Insert and display a single random hologram
hologram = randi([0, 255], N, M, 'uint8');
offset = 100;
slm.InsertHolograms(hologram, offset);
slm.SetHologram(offset);

%% Test 2: Define and start a sequence covering all holograms
sequence = uint64(0:(MAX_HOLOGRAMS - 1));
slm.SetHologramSequence(sequence);
slm.StartSequence(MAX_HOLOGRAMS);

%% Test 3: Generate and upload multiple phase-based holograms
x = linspace(-1, 1, M);
y = linspace(-M / N, M / N, N);
[y_grid, x_grid] = meshgrid(x, y);

wedge = @(alpha, beta) beta * x_grid + alpha * y_grid;
holograms = zeros(N, M, MAX_HOLOGRAMS, 'uint8');
for idx = 1:MAX_HOLOGRAMS
    alpha = 50 * (rand() - 0.5);
    beta = 50 * (rand() - 0.5);
    phase = wedge(alpha, beta);
    holograms(:, :, idx) = uint8(255 * (mod(phase, 2 * pi) / (2 * pi)));
end

slm.InsertHolograms(holograms, 0);
slm.SetHologram(0);
slm.SetHologramSequence(sequence);

%% Shutdown and release the library
slm.Cleanup();