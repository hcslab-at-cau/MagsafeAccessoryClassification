function cm = func_confusion_matrix(Y, pred, labels, testLabels, summary)
% Y for true labels, pred for predicted labels
% labels for total labels, testLabels for tested labels
% tested labels is need for index matching

cm = zeros(length(labels), length(labels) + 1); % + 1 for Not detected

% Attach accuracy
for cnt = 1:length(Y)
    pos = find(ismember(labels, Y(cnt)));
    tPos = find(ismember(labels, pred(cnt)));
    
    if pos == tPos
        cm(pos, pos) = cm(pos, pos) + 1;
    else
        cm(pos, tPos) = cm(pos, tPos) + 1;
    end
end

detachND = summary.nEvent(1:end-1) - summary.dAcc(1:end - 1, 2);
attachND = summary.nEvent(1:end-1) - summary.dAcc(1:end - 1, 1);

% detachND = summary.nEvent(1:end-1) - summary.b(1:end - 1, 2);
% attachND = summary.nEvent(1:end-1) - summary.a(1:end - 1, 1);

% Detach accuracy
for cnt = 1:length(summary.b)-1
    % 'cnt'-th in test labels are positioned at 'pos' in labels.
    pos = find(ismember(labels, testLabels(cnt)));

    % cm(pos, pos) = cm(pos, pos) + summary.b(cnt, 2);
    cm(pos, pos) = cm(pos, pos) + summary.dAcc(cnt, 2);
    cm(pos, end) = detachND(cnt) + attachND(cnt);
end

% Detach - Not detected
% cm(:, end) = summary.nEvent(1:end-1) - summary.b(1:end - 1, 2);

% Attach - Not detected
% cm(:, end) = cm(:, end) + summary.nEvent(1:end-1) - summary.a(1:end - 1, 1);

% cm
% Pertenage
for cnt = 1:length(summary.nEvent)-1
    pos = find(ismember(labels, testLabels(cnt)));
    attached = length(find(ismember(Y, testLabels(cnt))));
    
    cm(pos, :) = cm(pos, :) / (attached + (summary.nEvent(cnt)));
end
end

