classdef RTree < handle 
    properties
        root;           % Root node (RTreeNode)
        maxEntries;     % Maximum entries per non-leaf node (d)
        minEntries;     % Minimum entries per non-leaf node 
        maxPolygons;    % Maximum number of polygons (n)
        minPolygons;    % Minimum number of polygons during split
    end

    methods
        function obj = RTree(maxEntries, maxPolygons, minEntries, minPolygons)
            obj.maxEntries = maxEntries;
            if nargin < 2
                obj.maxPolygons = maxEntries;
            else
                obj.maxPolygons = maxPolygons;
            end
            if nargin < 3
                obj.minEntries = int32(maxEntries / 2);
            else
                obj.minEntries = minEntries;
            end
            if nargin < 4
                obj.minPolygons = int32(maxPolygons / 2);
            else
                obj.minPolygons = minPolygons;
            end

            % Initialize root node
            obj.root = RTreeNode();
            obj.root.isLeaf = true;
            obj.root.level = 1;
        end
        
        function obj = insert(obj, mbr, data)
            % Create the entry to be inserted
            newEntry = RTreeNodeEntry(mbr, data);

            % Find an appropriate leaf node for insertion
            chosenNode = obj.chooseLeaf(obj.root, newEntry.mbr);

            % Insert into the node
            chosenNode.entries{end + 1} = newEntry;

            % Handle split and adjust MBRs
            obj.adjustTree(chosenNode);
        end

        function build(obj, mbrs, geometries, showProgress)
            n = length(mbrs);
            if nargin < 3
                geometries = mbrs;
            end
            if nargin < 4
                showProgress = false;
            end
            if showProgress
                f = waitbar(0);
            end
            assert(length(geometries) == n);
            for i=1:n
                if showProgress && mod(i, 100) == 0
                    waitbar(i/n, f, sprintf('Building index for %s... (%d / %d)', inputname(1), i, n));
                end
                obj.insert(mbrs(i, :), geometries(i));
            end
            if showProgress
                close(f);
            end
        end

        function stats = summary(obj, print)
            if nargin < 2
                print = false;
            end
            nonLeafCnt = 0;
            leafCnt = 0;
            queue = Queue(); % Contains RTreeNode
            queue.push(obj.root)
            while (~queue.isempty())
                node = queue.pop();
                if node.isLeaf == 1
                    leafCnt = leafCnt + 1;
                else
                    nonLeafCnt = nonLeafCnt + 1;
                    for i=1:length(node.entries)
                        % Non-leaf node
                        entry = node.entries{i};
                        queue.push(entry.child);
                    end
                end
            end
            stats.nonLeafCnt = nonLeafCnt;
            stats.leafCnt = leafCnt;
            stats.height = obj.root.level;
            if print
                fprintf('Summary for %s:\n', inputname(1));
                disp(stats);
            end
        end

        function [entries, stats] = windowQuery(obj, searchMbr)
            compareCount = 0;
            entries = {};

            % Breadth-first search
            queue = Queue(); % Contains (RTreeNode)
            queue.push(obj.root)
            while (~queue.isempty())
                node = queue.pop();
                for i=1:length(node.entries)
                    entry = node.entries{i};
                    compareCount = compareCount + 1;
                    if RTree.calculateOverlap(entry.mbr, searchMbr) > 0
                        if isa(entry.child, 'RTreeNode')
                            queue.push(entry.child);
                        elseif all(entry.mbr(1:2) >= searchMbr(1:2)) && ...
                                    all(entry.mbr(3:4) <= searchMbr(3:4))
                            entries{end+1} = entry;
                        end
                    end
                end
            end
            stats.compareCount = compareCount;
        end
    end

    methods (Access = private)
        function leafNode = chooseLeaf(obj, node, mbr)
            if node.isLeaf
                % Leaf check
                leafNode = node;
            else
                % Choose the entry whose rectangle needs minimum enlargement
                minOverlap = Inf;
                minOverlapIndex = 0;
                for i=1:numel(node.entries)
                    entry = node.entries{i};
                    overlap = RTree.calculateOverlapIncrease(entry.mbr, mbr);
                    if overlap < minOverlap
                        % A smaller enlargement
                        minOverlap = overlap;
                        minOverlapIndex = i;
                    elseif overlap == minOverlap
                        % Resolve ties by choosing the entry with the
                        % rectangle of smallest area
                        if RTree.calculateMbrArea(entry.mbr) < ...
                                RTree.calculateMbrArea( ...
                                    node.entries{minOverlapIndex}.mbr)
                            minOverlapIndex = i;
                        end
                    end
                end
                % Search the minimum increase in the next level
                leafNode = obj.chooseLeaf( ...
                    node.entries{minOverlapIndex}.child, mbr);
            end
        end

        function [newNode1, newNode2] = split(obj, node)
            [seed1, seed2] = RTree.quadraticPickSeeds(node.entries);

            newNode1 = RTreeNode({node.entries{seed1}}, node.isLeaf, node.level);
            newNode2 = RTreeNode({node.entries{seed2}}, node.isLeaf, node.level);

            newNode1.parent = node.parent;
            newNode2.parent = node.parent;

            n = length(node.entries);
            remainingEntries = n - 2;

            for i=1:n
                if i == seed1 || i == seed2
                    continue;
                end
                entry = node.entries{i};
                if (~node.isLeaf && length(newNode1.entries) + remainingEntries == obj.minEntries) || ...
                    (node.isLeaf && length(newNode1.entries) + remainingEntries == obj.minPolygons)
                    for j=i:n
                        if j == seed1 || j == seed2
                            continue;
                        end
                        newNode1.entries{end + 1} = node.entries{j};
                    end
                    break;
                elseif (~node.isLeaf && length(newNode2.entries) + remainingEntries == obj.minEntries) || ...
                        (node.isLeaf && length(newNode2.entries) + remainingEntries == obj.minPolygons)
                    for j=i:n
                        if j == seed1 || j == seed2
                            continue;
                        end
                        newNode2.entries{end + 1} = node.entries{j};
                    end
                    break;
                else
                    increase1 = RTree.calculateGroupIncrease(newNode1.entries, entry);
                    increase2 = RTree.calculateGroupIncrease(newNode2.entries, entry);
    
                    if increase1 < increase2 || ...
                            (increase1 == increase2 && ...
                             length(newNode1.entries) < length(newNode2.entries))
                        newNode1.entries{end + 1} = entry;
                    else
                        newNode2.entries{end + 1} = entry;
                    end
                    remainingEntries = remainingEntries - 1;
                end
            end
        end

        function obj = adjustTree(obj, node)
            while ~isempty(node)
                n = length(node.entries);
                if (node.isLeaf && n > obj.maxPolygons) || ...
                    (~node.isLeaf && n > obj.maxEntries)
                    % If the node is full, split it
                    [newNode1, newNode2] = obj.split(node);

                    newNode1.level = node.level;
                    newNode2.level = node.level;

                    % Replace the original parent node with the two new nodes
                    if isempty(node.parent)
                        % If the parent node is the root, create a new root
                        newRoot = RTreeNode( ...
                            {RTreeNodeEntry(RTree.findMbr(newNode1.entries), newNode1), ...
                            RTreeNodeEntry(RTree.findMbr(newNode2.entries), newNode2)}, ...
                            false, node.level + 1);
                        newNode1.parent = newRoot;
                        newNode2.parent = newRoot;
                        obj.root = newRoot;

                        parent = newRoot;
                    else
                        newNode1.parent = node.parent;
                        newNode2.parent = node.parent;
                        parentEntryIdx = cellfun(@(x) x.child == node, node.parent.entries);
                        node.parent.entries{parentEntryIdx} = RTreeNodeEntry(RTree.findMbr(newNode1.entries), newNode1);
                        node.parent.entries{end + 1} = RTreeNodeEntry(RTree.findMbr(newNode2.entries), newNode2);
                        
                        parent = node.parent;
                    end
                    
                    % Update parent references
                    for i=1:length(newNode1.entries)
                        if isa(newNode1.entries{i}.child, 'RTreeNode')
                            newNode1.entries{i}.child.parent = newNode1;
                        end
                    end
                    for i=1:length(newNode2.entries)
                        if isa(newNode2.entries{i}.child, 'RTreeNode')
                            newNode2.entries{i}.child.parent = newNode2;
                        end
                    end
                else
                    % No need to split, just adjust the MBR
                    if isa(node.parent, 'RTreeNode')
                        % Update the MBR of the current node's entry in its parent
                        parentEntryIdx = cellfun(@(x) x.child == node, node.parent.entries);
                        newMbr = RTree.findMbr(node.entries);
                        if isequal(newMbr, node.parent.entries{parentEntryIdx}.mbr)
                            return;
                        end
                        node.parent.entries{parentEntryIdx}.mbr = RTree.findMbr(node.entries);
                    end
                    parent = node.parent;
                end

                % Move up the tree
                node = parent;
            end
        end
    end

    methods (Static, Access = private)
        function [seed1, seed2] = quadraticPickSeeds(entries)
            % Goal: Select two initial entries from the original node to
            % maximize the space wastage between the two entries.
            maxWaste = -Inf;
            seed1 = 0;
            seed2 = 0;
    
            for i=1:length(entries)
                for j=i+1:length(entries)
                    combinedMbr = RTree.combineMbrs(entries{i}.mbr, entries{j}.mbr);
                    % d = area(J) - area(E_1, I) - area(E_2, I)
                    currWaste = ...
                        RTree.calculateMbrArea(combinedMbr) - ...
                        RTree.calculateMbrArea(entries{i}.mbr) - ...
                        RTree.calculateMbrArea(entries{j}.mbr);
    
                    if currWaste > maxWaste
                        % Found a pair with larger space wastage
                        maxWaste = currWaste;
                        seed1 = i;
                        seed2 = j;
                    end
                end
            end
        end

        function overlap = isOverlap(mbr1, mbr2)
            % Check whether the two MBRs overlap
            if length(mbr1) == 4 && length(mbr2) == 4
                overlap = (mbr1(1) <= mbr2(3)) && (mbr1(3) >= mbr2(1)) && ...
                    (mbr1(2) <= mbr2(4)) && (mbr1(4) >= mbr2(2));
            else
                error('Invalid data type. Must be a vector of size 4.');
            end
        end
        
        function area = calculateMbrArea(mbr)
            % Calculate the MBR's area
            area = (mbr(3) - mbr(1)) * (mbr(4) - mbr(2));
        end
        
        function mbr = findMbr(entries)
            % Find the MBR based on a cell of entries
            mbr = [inf, inf, -inf, -inf];
            for i=1:length(entries)
                entry = entries{i};
                mbr = RTree.combineMbrs(mbr, entry.mbr);
            end
        end

        function combinedMbr = combineMbrs(mbr1, mbr2)
            % Combine two MBRs into one
            if numel(mbr1) ~= 4 || numel(mbr2) ~= 4
                error('Both MBRs should have 4 elements');
            end
            combinedMbr = [
                min(mbr1(1), mbr2(1)), ... % min x1
                min(mbr1(2), mbr2(2)), ... % min y1
                max(mbr1(3), mbr2(3)), ... % max x2
                max(mbr1(4), mbr2(4))  ... % max y2
            ];
        end
        
        function overlap = calculateOverlap(mbr1, mbr2)
            % Calculate the area of the intersection region of two 
            % overlapping MBRs
            intersectionMbr = [
                max(mbr1(1), mbr2(1)), ...
                max(mbr1(2), mbr2(2)), ...
                min(mbr1(3), mbr2(3)), ...
                min(mbr1(4), mbr2(4))
            ];
            if RTree.isOverlap(mbr1, mbr2)
                overlap = (intersectionMbr(3) - intersectionMbr(1)) * ...
                    (intersectionMbr(4) - intersectionMbr(2));
            else
                overlap = 0;
            end
        end
        
        function increase = calculateOverlapIncrease(mbr1, mbr2)
            % Calculate the increase in overlap after combining two MBRs
            combinedMbr = RTree.combineMbrs(mbr1, mbr2);

            overlapBefore = RTree.calculateOverlap(mbr1, mbr2);
            overlapAfter = RTree.calculateOverlap(combinedMbr, mbr2);
            
            increase = overlapAfter - overlapBefore;
        end

        function increase = calculateGroupIncrease(group, newEntry)
            currentMbr = RTree.findMbr(group);
            extendedMbr = RTree.findMbr(horzcat(group, {newEntry}));
        
            currentArea = RTree.calculateMbrArea(currentMbr);
            extendedArea = RTree.calculateMbrArea(extendedMbr);
        
            increase = extendedArea - currentArea;
        end
    end
end

