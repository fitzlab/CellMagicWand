function [] = gcampGradientCells(gradientX, gradientY, img)
    % Finds cells in img, given gradients in the X and Y direction.
    % Process:
    % (1) Find the gradient magnitude image. Keep only the pixels of
    % magnitude above the Otsu threshold.
    % (2) Find 