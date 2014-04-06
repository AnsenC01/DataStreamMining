function dictionaryrmse
%% ��д�ļ�Ŀ¼ %%
tic;
%read_directory1 = 'dataset/batch_data_segment/topics_data1/update_vsm';
%dictionary_filename = 'dataset/general_ksvd/topics_data1/�ֵ�.txt';

read_directory1 = 'D:/Local/workspace/MicroblogDataStreamCompress/dataset/batch_data_segment/Music/Music2/update_vsm';
%dictionary_filename = 'dataset/general_ksvd/Music2000/5/�ֵ�5.txt';
dictionary_filename = 'dataset/non_orthogonal/Music2/�ֵ�.txt';

ompparams = {'checkdict', 'off'};
ompparams{end + 1} = 'messages';
ompparams{end + 1} = -1;

thresh = 25;

%write_directory = 'dataset/general_ksvd/topics_data1/error';
%write_directory = 'dataset/general_ksvd/Music2000/5/error';
write_directory = 'dataset/non_orthogonal/Music2/error';

if ~isdir(write_directory)
    mkdir(write_directory);
end

data_files = dir(fullfile(read_directory1, '*.txt'));
D = load(dictionary_filename);

error_matrix = zeros(length(data_files), 1);

for i = 1 : length(data_files)
    data = load(strcat(strcat(read_directory1, '/'), strcat(num2str(i), '.txt')));
    data = data';
    printf('���ڴ����%dƬ����', i);
    
    %D = load(strcat(strcat(read_directory2, '/'), dictionary_files(j).name));
    %D = xlsread(strcat(strcat(read_directory2, '/'), dictionary_files(j).name));
    %Gamma = OMP(D, data, thresh);    % ������OMPЧ����һ���ģ����������2��������
    Gamma = omp(D' * data, D' * D, thresh, ompparams{:});
    error_matrix(i, 1) = compute_err(D, Gamma, data);
    printf('��%dƬ���ݴ������\n', i);
end

write_filename = strcat(write_directory, '/�ֵ��ع����.xlsx');
xlswrite(write_filename, error_matrix);
toc;
end



%% ����в� %%
function err = compute_err(D, Gamma, data)
% ����ϡ������ƵĲв����
err = sqrt(sum(reperror2(data, D, Gamma)) / numel(data));
end


%% �ֿ����в��ƽ����
function err2 = reperror2(X,D,Gamma)
%XX = zeros(size(X, 1), size(X,2));
err2 = zeros(1, size(X, 2));
blocksize = 2000;
for i = 1 : blocksize : size(X, 2)
    blockids = i : min(i + blocksize - 1, size(X, 2));
    %XX(:,blockids) = round(D * Gamma(:, blockids));
    err2(blockids) = sum((X(:, blockids) - round(D * Gamma(:, blockids))) .^ 2);
end
%xlswrite('XX.xlsx', XX);
end


