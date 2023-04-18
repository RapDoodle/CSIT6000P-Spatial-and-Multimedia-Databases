classdef RTreeNodeEntry < handle 
    properties
        id;
        mbr; % Format: [minX, minY, maxX, maxY]
        child; % Should be an RTreeNode object or an MBR
    end
    
    methods
        function obj = RTreeNodeEntry(mbr, child)
            obj.mbr = mbr;
            obj.child = child;
            obj.id = RTreeNodeEntry.getId();
        end

        function res = isequal(self, other)
            res = isequal(self.id, other.id);
        end
    end

    methods (Static)
        function count = getId()
            persistent objCount;
            if isempty(objCount)
                objCount = 1;
            else
                objCount = objCount + 1;
            end
            count = objCount;
        end
    end
end

