function ENreconstruct

%������ѹ�������ع�
%  ��������OMP�㷨�ع�
%  �������������ع�

%  B506
%  Computer Science School
%  Wuhan University, Wuhan 430072 China
%  zhujiahui@whu.edu.cn
%  2013-12-31

%% ��д�ļ�Ŀ¼ %%
tic;
read_directory1 = 'dataset/pyramid2/Music5/data';

Q_filename = 'dataset/non_orthogonal/Music5/Q.txt';
dictionary_filename = 'dataset/non_orthogonal/Music5/�ֵ�.txt';

write_directory = 'dataset/pyramid2/Music5/reconstruct_data';

if ~isdir(write_directory)
    mkdir(write_directory);
end

Q = load(Q_filename);
D = load(dictionary_filename);
D1 = Q * D;

% ϡ���25
thresh = 25;

data_files = dir(fullfile(read_directory1, '*.txt'));

for i = 1 : length(data_files)
    data = load(strcat(strcat(read_directory1, '/'), strcat(num2str(i), '.txt')));
    printf('���ڴ����%dƬ����', i);
    
    % ��ǰ����Ƭ�ع�
    S = OMP(D1, data, thresh);
    % ÿһ�д���һ������
    reconstruct_data = round(D * S);
    
    dlmwrite(strcat(strcat(write_directory, '/'), strcat(num2str(i), '.txt')), full(reconstruct_data), ' ');
    printf('��%dƬ���ݴ������\n', i);
end

time = toc;
fprintf('��ʱ%f��\n', time);

end
