function originalcluster

%��2��Ϊ��λ���о���
%  ����ķ�ʽ�����׾���

%  B506
%  Computer Science School
%  Wuhan University, Wuhan 430072 China
%  zhujiahui@whu.edu.cn
%  2013-12-31

%% ��д�ļ�Ŀ¼ %%
tic;

% �ع��Ķ���Ϊ������ѹ���������
% �ع���Ƭ���У�����Ϊʱ��
read_directory1 = 'dataset/cluster/topics_data22/original_merge_vsm';

write_directory1 = 'dataset/cluster/o2/original_cluster_center';
write_directory2 = 'dataset/cluster/o2/original_each_cluster_number';
write_directory3 = 'dataset/cluster/o2/original_cluster_tag';

if ~isdir(write_directory1)
    mkdir(write_directory1);
end

if ~isdir(write_directory2)
    mkdir(write_directory2);
end

if ~isdir(write_directory3)
    mkdir(write_directory3);
end

% �������������Ƭ��
data_files = dir(fullfile(read_directory1, '*.txt'));

cluster_number = 2;
ev_number = 6;

for i  = 1 : length(data_files)
    
    fprintf('���ڴ����%dƬ����\n', i);
    
    data = load(strcat(strcat(read_directory1, '/'), strcat(num2str(i), '.txt')));
    data_length = size(data, 1);
    
    each_batch = 500;
    batch_number = floor(data_length / each_batch);
    row = 1;
    
    merge_center_data = zeros(size(data, 2), cluster_number * batch_number);
    merge_cluster_number = zeros(batch_number * cluster_number, 1);
    merge_cluster_tag = zeros(each_batch * batch_number, 1);
    
    center_count = 0;
    
    % �ֲ�����
    for j = 1 : batch_number
        data2 = data(row : (row + each_batch - 1), :);
        
        % ����
        [cluster_tag, center, sum_to_center, each_to_center] = spectral_cluster(data2, cluster_number, ev_number);
        
        % �������
        for k = 1 : size(each_to_center, 2)
            [min_value, min_index] = min(each_to_center(:, k));
            merge_center_data(:, center_count + k) = data(min_index, :);
        end
        
        each_cluster_number = zeros(cluster_number, 1);
        for k = 1 : length(cluster_tag)
            for l = 1 : cluster_number
                if cluster_tag(k) == l
                    each_cluster_number(l, 1) = each_cluster_number(l, 1) + 1;
                end
            end
        end
        
        
        for k = 1 : cluster_number
            merge_cluster_number((2 * j + k - 2), 1) = each_cluster_number(k, 1);
        end
        
        merge_cluster_tag(row : (row + each_batch -1), 1) = cluster_tag;
        
        center_count = center_count + cluster_number;
        row = row + each_batch;
    end
    
    
    
    % ���ܾ���
    [cluster_tag, center, sum_to_center, each_to_center] = spectral_cluster(merge_center_data', cluster_number, ev_number);
    
    % �������
    center_data = zeros(size(merge_center_data, 1), cluster_number);
    
    for k = 1 : size(each_to_center, 2)
        [min_value, min_index] = min(each_to_center(:, k));
        center_data(:, k) = data(min_index, :);
    end
    
    final_each_cluster_number = zeros(cluster_number, 1);
    for k = 1 : length(cluster_tag)
        for l = 1 : cluster_number
            if cluster_tag(k) == l
                final_each_cluster_number(l, 1) = final_each_cluster_number(l, 1) + merge_cluster_number(k, 1);
            end
        end
        
        % ֻ��2���࣬��ö��
        if mod(k, 2) == 1
            for kk = 1 : each_batch
                part = (k + 1) / 2;
                if merge_cluster_tag((part - 1) * each_batch + kk) == 1
                    merge_cluster_tag((part - 1) * each_batch + kk) = cluster_tag(k);
                end
            end
        else
            for kk = 1 : each_batch
                part = k / 2;
                if merge_cluster_tag((part - 1) * each_batch + kk) == 2
                    merge_cluster_tag((part - 1) * each_batch + kk) = cluster_tag(k);
                end
            end
        end
    end
    
    % ��ǰ��ľ������ݣ��������ģ�д���ļ�
    % д���ÿһ�д���һ����Ϣ
    dlmwrite(strcat(strcat(write_directory1, '/'), strcat(num2str(i), '.txt')), center_data, ' ');
    dlmwrite(strcat(strcat(write_directory2, '/'), strcat(num2str(i), '.txt')), final_each_cluster_number, ' ');
    dlmwrite(strcat(strcat(write_directory3, '/'), strcat(num2str(i), '.txt')), merge_cluster_tag, ' ');
    
    fprintf('��%dƬ���ݾ������\n', i);
    
end

fprintf('�������ݾ������\n');

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
    
    %if size(norm_select_E_vectors, 1) >= cluster_number
    
    % K-Means����
    % ע��K-Means������������ݰ�����
    [cluster_tag, center, sum_to_center, each_to_center] = kmeans(norm_select_E_vectors, cluster_number, 'emptyaction','singleton');
    disp('finish the clustering!!!');
end

end
