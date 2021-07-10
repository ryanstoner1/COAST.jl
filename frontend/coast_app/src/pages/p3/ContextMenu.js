
import {useCallback, useState} from 'react';

export const handleNonchartClick = (e, hideContextMenu) => {
    if (!e.altKey) {
        hideContextMenu();
    }
};

// export default ContextMenu