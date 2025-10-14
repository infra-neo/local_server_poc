# Drag & Drop Features Documentation

## Overview

Kolaboree NG includes drag-and-drop functionality using **React DnD** (Drag and Drop) with the HTML5 backend. This provides an intuitive interface for advanced permission management and workspace assignment.

## Current Implementation

### Technologies Used
- **React DnD** v16.0.1 - Core drag and drop library
- **react-dnd-html5-backend** v16.0.1 - HTML5 drag and drop backend
- **Framer Motion** - For smooth animations

### UI Components

The AdminDashboard is wrapped in a `DndProvider` with the HTML5Backend:

```javascript
import { DndProvider } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';

<DndProvider backend={HTML5Backend}>
  {/* Dashboard content */}
</DndProvider>
```

## Available Drag & Drop Options

### 1. User-to-Machine Assignment (Future Enhancement)

**Purpose**: Drag users to VMs/containers to assign access permissions

**Implementation Strategy**:
```javascript
// Define draggable user component
const DraggableUser = ({ user }) => {
  const [{ isDragging }, drag] = useDrag(() => ({
    type: 'USER',
    item: { id: user.id, username: user.username },
    collect: (monitor) => ({
      isDragging: monitor.isDragging()
    })
  }));
  
  return <div ref={drag}>...</div>
};

// Define droppable machine component
const DroppableMachine = ({ machine, onUserDrop }) => {
  const [{ isOver }, drop] = useDrop(() => ({
    accept: 'USER',
    drop: (item) => onUserDrop(item, machine),
    collect: (monitor) => ({
      isOver: monitor.isOver()
    })
  }));
  
  return <div ref={drop}>...</div>
};
```

### 2. Cloud Connection Reordering

**Purpose**: Drag cloud connection cards to reorder them by priority

**Use Case**: Organize connections by importance or usage frequency

```javascript
const DraggableCloudCard = ({ connection, index, moveCard }) => {
  const [{ isDragging }, drag] = useDrag({
    type: 'CLOUD_CARD',
    item: { id: connection.id, index },
    collect: (monitor) => ({
      isDragging: monitor.isDragging()
    })
  });
  
  const [, drop] = useDrop({
    accept: 'CLOUD_CARD',
    hover: (item) => {
      if (item.index !== index) {
        moveCard(item.index, index);
        item.index = index;
      }
    }
  });
  
  return <div ref={(node) => drag(drop(node))}>...</div>
};
```

### 3. Workspace Assignment

**Purpose**: Drag workspaces to users to assign them

**Workflow**:
1. Admin drags a workspace (VM/Container)
2. Drops it on a user
3. System creates assignment and configures access

### 4. Resource Grouping

**Purpose**: Drag multiple VMs into groups for organizational purposes

**Use Cases**:
- Group by project
- Group by environment (dev, staging, prod)
- Group by department

### 5. Permission Templates

**Purpose**: Drag permission templates to users or groups

**Benefits**:
- Quick role-based access control
- Consistent permission application
- Visual permission management

## Advanced Drag & Drop Patterns

### Multi-Select Drag

Enable dragging multiple items at once:

```javascript
const [selectedItems, setSelectedItems] = useState([]);

const handleDrag = useDrag({
  type: 'MULTI_ITEM',
  item: { items: selectedItems },
  // ...
});
```

### Conditional Drop Zones

Only allow drops on compatible targets:

```javascript
const [{ canDrop, isOver }, drop] = useDrop({
  accept: 'USER',
  canDrop: (item) => {
    // Custom validation logic
    return item.role === 'developer' && machine.type === 'development';
  },
  collect: (monitor) => ({
    canDrop: monitor.canDrop(),
    isOver: monitor.isOver()
  })
});
```

### Visual Feedback

Provide clear visual feedback during drag operations:

```javascript
<Box
  sx={{
    opacity: isDragging ? 0.5 : 1,
    backgroundColor: isOver ? 'primary.light' : 'background.paper',
    border: canDrop ? '2px dashed green' : 'none',
    cursor: isDragging ? 'grabbing' : 'grab'
  }}
>
  {/* Content */}
</Box>
```

## Backend API Support

To support drag-and-drop operations, implement these endpoints:

```python
# Assign user to workspace
@router.post("/workspaces/{workspace_id}/assign")
async def assign_workspace(workspace_id: str, user_id: str):
    # Implementation
    pass

# Update resource group
@router.put("/resources/groups")
async def update_resource_group(resources: List[str], group_id: str):
    # Implementation
    pass

# Apply permission template
@router.post("/permissions/apply-template")
async def apply_permission_template(template_id: str, target_id: str):
    # Implementation
    pass
```

## Best Practices

1. **Accessibility**: Always provide keyboard alternatives to drag-and-drop
2. **Mobile Support**: Consider touch-friendly alternatives for mobile devices
3. **Visual Feedback**: Use animations and color changes to indicate drag state
4. **Validation**: Validate drops on both client and server side
5. **Undo/Redo**: Provide undo functionality for accidental drops
6. **Confirmation**: Show confirmation dialogs for critical operations

## Example: Complete User-to-VM Assignment

```javascript
import { useDrag, useDrop } from 'react-dnd';

// User Card (Draggable)
const UserCard = ({ user }) => {
  const [{ isDragging }, drag] = useDrag(() => ({
    type: 'USER',
    item: { userId: user.id, username: user.username },
    collect: (monitor) => ({
      isDragging: monitor.isDragging()
    })
  }));

  return (
    <Card ref={drag} sx={{ opacity: isDragging ? 0.5 : 1 }}>
      <CardContent>
        <Typography>{user.username}</Typography>
      </CardContent>
    </Card>
  );
};

// VM Card (Drop Target)
const VMCard = ({ vm, onAssignUser }) => {
  const [{ isOver, canDrop }, drop] = useDrop(() => ({
    accept: 'USER',
    drop: (item) => {
      onAssignUser(item.userId, vm.id);
    },
    collect: (monitor) => ({
      isOver: monitor.isOver(),
      canDrop: monitor.canDrop()
    })
  }));

  return (
    <Card 
      ref={drop}
      sx={{ 
        backgroundColor: isOver && canDrop ? 'success.light' : 'background.paper',
        border: canDrop ? '2px dashed green' : 'none'
      }}
    >
      <CardContent>
        <Typography>{vm.name}</Typography>
        {isOver && <Typography>Drop to assign</Typography>}
      </CardContent>
    </Card>
  );
};
```

## Integration with Kolaboree Features

### With Guacamole Remote Access
- Drag users to VMs to automatically configure Guacamole connections
- Drop permission templates to set up RDP/VNC/SSH access

### With User Management
- Drag users between groups
- Assign roles via drag and drop

### With Multi-Cloud Management
- Organize resources across different cloud providers
- Create visual deployment pipelines

## Future Enhancements

1. **Batch Operations**: Drag multiple items simultaneously
2. **Smart Suggestions**: AI-powered recommendations for optimal assignments
3. **History**: Track all drag-and-drop operations for audit
4. **Templates**: Save common drag-and-drop patterns as templates
5. **Real-time Collaboration**: See other admins' drag operations in real-time

## References

- [React DnD Documentation](https://react-dnd.github.io/react-dnd/)
- [HTML5 Backend](https://react-dnd.github.io/react-dnd/docs/backends/html5)
- [Drag and Drop Accessibility](https://www.w3.org/WAI/ARIA/apg/patterns/drag-and-drop/)
