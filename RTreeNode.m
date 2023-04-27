classdef RTreeNode < handle
    properties
        entries;    % Array of RTreeNodeEntry objects
        isLeaf;     % Boolean indicating if the node is a leaf node
        parent;     % Parent node (RTreeNode)
        level;      % Level of the node in the RTree
    end

    methods
        function obj = RTreeNode(entries, isLeaf, level)
            if nargin >= 1
                obj.entries = entries;
            else
                obj.entries = {};
            end

            if nargin >= 2
                obj.isLeaf = isLeaf;
            else
                obj.isLeaf = false;
            end

            if nargin >= 3
                obj.level = level;
            else
                obj.level = 0;
            end

            obj.parent = [];
        end
    end
end

