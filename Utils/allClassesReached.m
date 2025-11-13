function tf = allClassesReached(countStruct, classNames, goalPerClass)
if goalPerClass <= 0, tf = true; return; end
tf = true;
for i = 1:numel(classNames)
    if countStruct.(classNames{i}) < goalPerClass, tf = false; return; end
end
end

