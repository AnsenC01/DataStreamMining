function ENgeneratetopics

%�ھ���
%  ����ʱ��ѡ������
%  ��������OMP�㷨�ع�
%  �����ع��Ŀռ��ھ���
%  ����ķ��������׾���
%  ���ݾ��������ھ���

%  B506
%  Computer Science School
%  Wuhan University, Wuhan 430072 China
%  zhujiahui@whu.edu.cn
%  2013-12-31

date_start = '2013-02-15';
date_end = '2013-02-25';

% ѹ��������ʱ�����Ӧ��ϵ 1970-01-01 0:00:00 = -28800
start_unix_time = (datenum(date_start) - datenum('1970-01-01')) * 86400;
end_unix_time = (datenum(date_end) - datenum('1970-01-01')) * 86400;

%% ��д�ļ�Ŀ¼ %%
tic;

% �ع��Ķ���Ϊ������ѹ���������
% �ع���Ƭ���У�����Ϊʱ��
read_directory1 = 'dataset/pyramid/Music5/data';
read_directory2 = 'dataset/pyramid/Music5/phst';
read_directory3 = 'dataset/pyramid/Music5/original_index';

Q_filename = 'dataset/non_orthogonal/Music5/Q.txt';
dictionary_filename = 'dataset/non_orthogonal/Music5/�ֵ�.txt';

write_directory1 = 'dataset/cluster/Music5/cluster_center';
write_directory2 = 'dataset/cluster/Music5/each_cluster_number';

write_date_filename = 'dataset/cluster/Music5/date.txt';
batch_index_filename = 'dataset/cluster/Music5/batch_index.txt';

if ~isdir(write_directory1)
    mkdir(write_directory1);
end
if ~isdir(write_directory2)
    mkdir(write_directory2);
end


Q = load(Q_filename);
D = load(dictionary_filename);
D1 = Q * D;

% ϡ���25
thresh = 25;

% ���ܵĴ������������Ƭ��
data_files = dir(fullfile(read_directory1, '*.txt'));
file_number = 1;

fid_d = fopen(write_date_filename, 'w+');

for i = 1 : length(data_files)
    % ע��˴����ַ�������
    fid = fopen(strcat(strcat(read_directory2, '/'), strcat(num2str(i), '.txt')));
    phst = textscan(fid, '%s %s %s %f');
    fclose(fid);
    
    if phst{1, 4}(end) < start_unix_time
        fprintf('Skip\n');
    elseif phst{1, 4}(1) > end_unix_time
        break
    else
        % ѹ���Ľ��������ݰ��д洢��ÿһ�д���һ������
        pyramid_data = load(strcat(strcat(read_directory1, '/'), strcat(num2str(i), '.txt')));
        % ������ѹ����������2�У���һ�б�ʾԭʼ����Ƭ��ţ��ڶ��б�ʾ����Ӧ����Ƭ�е�λ�ã����ߵı�Ŷ��Ǵ�1��ʼ
        original_index = load(strcat(strcat(read_directory3, '/'), strcat(num2str(i), '.txt')));
        
        candidate_j = intersect(find(phst{1, 4} >= start_unix_time), find(phst{1, 4} <= end_unix_time));
        
        j = candidate_j(1);
        previous_batch_id = original_index(j, 1);
        previous_time = start_unix_time;
        batch_data = [];
        
        while j <= candidate_j(end)
            this_batch_id = original_index(j, 1);
            this_unix_time = phst{1, 4}(j);
            
            %% while�ڵ�һ��if %%
            % ��Ҫ������ԭʼ��������ͬһƬ����Ҫ������ͬһ��
            if this_batch_id == previous_batch_id && (this_unix_time - previous_time) < 86400
                batch_data = [batch_data, pyramid_data(:, j)];
                
                % ������ĩβ�������
                if j == candidate_j(end)
                    %%%%% ������� %%%%%
                    % ��ǰ����Ƭ�ع�
                    S = OMP(D1, batch_data, thresh);
                    % ÿһ�д���һ������
                    reconstruct_data = round(D * S);
                
                    % ����
                    cluster_number = 3;
                    ev_number = 5;
                    if size(reconstruct_data, 2) <= ev_number
                        fprintf('\n����̫�٣��޷����࣡\n');
                    else                
                        [cluster_tag, center, sum_to_center, each_to_center] = spectral_cluster(reconstruct_data', cluster_number, ev_number);
                
                        % �������
                        center_data = zeros(size(reconstruct_data, 1), cluster_number);
                        for k = 1 : size(each_to_center, 2)
                            [min_value, min_index] = min(each_to_center(:, k));
                            center_data(:, k) = reconstruct_data(:, min_index);
                        end
                    
                        each_cluster_number = zeros(cluster_number, 1);
                        for k = 1 : length(cluster_tag)
                            for l = 1 : cluster_number
                                if cluster_tag(k) == l
                                    each_cluster_number(l, 1) = each_cluster_number(l, 1) + 1;
                                end
                            end
                        end
                                
                
                        % ��ǰ��ľ������ݣ��������ģ�д���ļ�
                        % д���ÿһ�д���һ����Ϣ
                        dlmwrite(strcat(strcat(write_directory1, '/'), strcat(num2str(file_number), '.txt')), center_data, ' ');
                        dlmwrite(strcat(strcat(write_directory2, '/'), strcat(num2str(file_number), '.txt')), each_cluster_number, ' ');
                        file_number = file_number + 1;
                        % ��ʱ����Ϣ��д���ļ����˴�ֻ��һ������
                        fprintf(fid_d, '%s\n', num2str(previous_time));
                        dlmwrite(batch_index_filename, this_batch_id, '-append', 'delimiter', ' ');                       
                    end
                    %%%%% ����������� %%%%%
                end
                
            %% while�ڵ�һ��else %%
            else
                %%%%% ������� %%%%%
                % ��ǰ����Ƭ�ع�
                S = OMP(D1, batch_data, thresh);
                % ÿһ�д���һ������
                reconstruct_data = round(D * S);
                
                % ����
                cluster_number = 3;
                ev_number = 5;
                if size(reconstruct_data, 2) <= ev_number
                    fprintf('\n����̫�٣��޷����࣡\n');
                else                
                    [cluster_tag, center, sum_to_center, each_to_center] = spectral_cluster(reconstruct_data', cluster_number, ev_number);
                
                    % �������
                    center_data = zeros(size(reconstruct_data, 1), cluster_number);
                    for k = 1 : size(each_to_center, 2)
                        [min_value, min_index] = min(each_to_center(:, k));
                        center_data(:, k) = reconstruct_data(:, min_index);
                    end
                    
                    each_cluster_number = zeros(cluster_number, 1);
                    for k = 1 : length(cluster_tag)
                        for l = 1 : cluster_number
                            if cluster_tag(k) == l
                                each_cluster_number(l, 1) = each_cluster_number(l, 1) + 1;
                            end
                        end
                    end
                                
                
                    % ��ǰ��ľ������ݣ��������ģ�д���ļ�
                    % д���ÿһ�д���һ����Ϣ
                    dlmwrite(strcat(strcat(write_directory1, '/'), strcat(num2str(file_number), '.txt')), center_data, ' ');
                    dlmwrite(strcat(strcat(write_directory2, '/'), strcat(num2str(file_number), '.txt')), each_cluster_number, ' ');
                    file_number = file_number + 1;
                    % ��ʱ����Ϣ��д���ļ����˴�ֻ��һ������
                    fprintf(fid_d, '%s\n', num2str(previous_time));
                    dlmwrite(batch_index_filename, previous_batch_id, '-append', 'delimiter', ' ');
                end
                %%%%% ����������� %%%%%
                
                if this_batch_id == previous_batch_id && (this_unix_time - previous_time) >= 86400
                    previous_time = previous_time + 86400;
                elseif this_batch_id ~= previous_batch_id && (this_unix_time - previous_time) < 86400
                    previous_batch_id = this_batch_id;
                else
                    previous_time = previous_time + 86400;
                    previous_batch_id = this_batch_id;
                end
                
                batch_data = pyramid_data(:, j);
            end
            %% while�ڵ�һ��end %%
            
            j = j + 1;
        end
    end
end

fclose(fid_d);

fprintf('\n�������ݾ������\n');
time = toc;
fprintf('��ʱ%f��\n', time);

end


%% �׾���
function [cluster_tag, center, sum_to_center, each_to_center] = spectral_cluster(data, cluster_number, ev_number)

% ����node֮������ƶȾ���
n = size(data, 1);  % �����������ݸ���
node_matrix = zeros(n, n);
degree_matrix = zeros(n, n);  %����Ⱦ���

for i = 1 : n
    for j = i : n
        d1 = KL_divergence(data(i, :), data(j, :));
        d2 = KL_divergence(data(j, :), data(i, :));
        node_matrix(i, j) = max(d1, d2);
        % node_matrix(i, j) = pdist2(data(i, :), data(j, :), 'Euclidean');
        node_matrix(j, i) = node_matrix(i, j);
    end
    degree_matrix(i, i) = sum(node_matrix(i, :));
end

disp('finish the node similarity computing!!!');

% �������ƶȾ����NJW�׾���
L_matrix = degree_matrix - node_matrix;  % ����������˹����
for i = 1 : n
    degree_matrix(i, i) = degree_matrix(i, i) ^ (-1 / 2);
end

L_matrix = degree_matrix * L_matrix * degree_matrix;  % ������˹����淶��

[E_vectors, E_values] = eig(L_matrix);
k = ev_number;  % ȡ���������ĸ���
if k > n
    fpfintf('\n���ݸ���̫�٣�\n');
else
    
    select_E_vectors = E_vectors(:, 1 : k);
    norm_select_E_vectors = zeros(n, k);

    % ���е�λ��
    for i = 1 : n
        for j = 1 : k
            norm_select_E_vectors(i, j) = select_E_vectors(i, j) / (sum(select_E_vectors(i, :) .^ 2) ^ (0.5));
        end
    end

    % K-Means����
    % ע��K-Means������������ݰ�����
    [cluster_tag, center, sum_to_center, each_to_center] = kmeans(norm_select_E_vectors, cluster_number);
    disp('finish the clustering!!!');
end

end
