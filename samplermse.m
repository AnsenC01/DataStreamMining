function samplermse
%% ��д�ļ�Ŀ¼ %%
tic;
read_directory1 = 'D:/Local/workspace/MicroblogDataStreamCompress/dataset/batch_data_segment/topics_data1/update_vsm';
dictionary_filename = 'dataset/non_orthogonal/topics_data1/�ֵ�.txt';

thresh = 20;

write_directory = 'dataset/non_orthogonal/topics_data1/error';
write_directory2 = 'dataset/non_orthogonal/topics_data1/�ع�����';

if ~isdir(write_directory)
    mkdir(write_directory);
end

if ~isdir(write_directory2)
    mkdir(write_directory2);
end

data_files = dir(fullfile(read_directory1, '*.txt'));
D = load(dictionary_filename);

error_matrix = zeros(length(data_files), 1);

for i = 1 : length(data_files)
    data = load(strcat(strcat(read_directory1, '/'), strcat(num2str(i), '.txt')));
    printf('���ڴ����%dƬ����', i);
    
    M_sample = 120;  % ����ά��
    L = size(data, 2);  % ԭʼ����ά��
    Q = normrnd(0, sqrt(1 / sqrt(M_sample)), M_sample, L);
    printf('���������ά�ȣ�%d * %d', size(Q, 1), size(Q, 2));
    
    data1 = Q * data';
    printf('���ݲ������ά�ȣ�%d * %d',size(data1, 1), size(data1, 2));

    data = data';
    
    D1 = Q * D;
    Gamma = OMP(D1, data1, thresh);    % ���OMP�Ƚ���
    data2 = (round(D * Gamma))';
    dlmwrite(strcat(strcat(write_directory2, '/'), strcat(num2str(i), '.txt')), full(data2), ' ');

    error_matrix(i, 1) = compute_err(D, Gamma, data);
    
    printf('��%dƬ���ݴ������\n', i);
end

write_filename = strcat(write_directory, '/�����ֵ��ع����.xlsx');
xlswrite(write_filename, error_matrix);

toc;
end



%% ����в� %%
function err = compute_err(D, Gamma, data)
% ����ϡ������ƵĲв����
err = sqrt(sum(reperror2(data, D, Gamma)) / numel(data));
end


%% �ֿ����в��ƽ����
function err2 = reperror2(X, D, Gamma)

err2 = zeros(1, size(X, 2));
blocksize = 2000;
for i = 1 : blocksize : size(X, 2)
    blockids = i : min(i + blocksize - 1, size(X, 2));
    err2(blockids) = sum((X(:, blockids) - round(D * Gamma(:, blockids))) .^ 2);
end
end


