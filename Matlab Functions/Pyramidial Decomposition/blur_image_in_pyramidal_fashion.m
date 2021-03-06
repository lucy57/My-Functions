function res = blur_image_in_pyramidal_fashion(mat_in, number_of_levels, filter_mat)
% RES = blur(IM, LEVELS, FILT)
%
% Blur an image, by filtering and downsampling LEVELS times
% (default=1), followed by upsampling and filtering LEVELS times.  The
% blurring is done with filter kernel specified by FILT (default =
% 'binom5'), which can be a string (to be passed to namedFilter), a
% vector (applied separably as a 1D convolution kernel in X and Y), or
% a matrix (applied as a 2D convolution kernel).  The downsampling is
% always by 2 in each direction.

%------------------------------------------------------------
% OPTIONAL ARGS:

if ~exist('number_of_levels','var')
    number_of_levels = 1;
end

if ~exist('filter_mat','var')
    filter_mat = 'binom5';
end

%------------------------------------------------------------

if ischar(filter_mat)
    filter_mat = get_filter_by_name(filter_mat);
end
filter_mat = filter_mat/sum(filter_mat(:));

if number_of_levels > 0
    if any(size(mat_in)==1)
        %if mat_in is a vector:
        if ~any(size(filter_mat)==1)
            error('Cant apply 2D filter to 1D signal');
        end
        
        %fit filter dimensions (row or column) to mat in:
        if (size(mat_in,2)==1)
            filter_mat = filter_mat(:);
        else
            filter_mat = filter_mat(:)';
        end
        
        %convolve, downsample, call function again and eventually upsample and convolve:
        in = corr2_downsample(mat_in,filter_mat,'reflect1',(size(mat_in)~=1)+1);
        out = blur_image_in_pyramidal_fashion(in, number_of_levels-1, filter_mat);
        res = upsample_inserting_zeros_convolve(out, filter_mat, 'reflect1', (size(mat_in)~=1)+1, [1 1], size(mat_in));
        
    elseif any(size(filter_mat)==1)
        %if mat_in is 2D but filter is 1D then operate on each dimension seperately:
        filter_mat = filter_mat(:);
        
        %convolve, downsample, call function again and eventually upsample and convolve:
        in = corr2_downsample(mat_in,filter_mat,'reflect1',[2 1]);
        in = corr2_downsample(in,filter_mat','reflect1',[1 2]);
        out = blur_image_in_pyramidal_fashion(in, number_of_levels-1, filter_mat);
        res = upsample_inserting_zeros_convolve(out, filter_mat', 'reflect1', [1 2], [1 1], [size(out,1),size(mat_in,2)]);
        res = upsample_inserting_zeros_convolve(res, filter_mat, 'reflect1', [2 1], [1 1], size(mat_in));
        
    else
        %both mat_in and filter are 2D mats:
        
        %convolve, downsample, call function again and eventually upsample and convolve:
        in = corrDn(mat_in,filter_mat,'reflect1',[2 2]);
        out = blur_image_in_pyramidal_fashion(in, number_of_levels-1, filter_mat);
        res = upConv(out, filter_mat, 'reflect1', [2 2], [1 1], size(mat_in));
    end
else
    res = mat_in;
end

