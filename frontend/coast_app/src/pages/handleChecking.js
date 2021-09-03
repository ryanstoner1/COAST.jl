
    const handleCheckX = (e,pointInd,pointCheck,xData,yData,setXData,setYData,checkedList,setMaxChecked) => {

        setXData(value => value.map(item=> {
            if (item.ind === pointInd & item.check === true) {
                return {ind: pointInd, val : [...item.val], check: false, disabled: item.disabled} 
            } else if (item.ind === pointInd & item.check === false) {
                return {ind: pointInd, val : [...item.val], check: true, disabled: item.disabled} 
            } else {
                return item
            }}))
        isCheckDisabled(xData,yData,checkedList,pointCheck,setXData,setYData,setMaxChecked)
    };

    const handleCheckY = (e,pointInd,pointCheck,xData,yData,setXData,setYData,checkedList,setMaxChecked) => {    
        setYData(value => value.map(item=> {
            
            if (item.ind === pointInd & item.check === true) {

                return {ind: pointInd, val : [...item.val], check: false, disabled: item.disabled} 
            } else if (item.ind === pointInd & item.check === false) {

                return {ind: pointInd, val : [...item.val], check: true, disabled: item.disabled} 
            } else {
                return item
            }}))
        isCheckDisabled(xData,yData,checkedList,pointCheck,setXData,setYData,setMaxChecked)
    };

    const isCheckDisabled = (xData,yData,checkedList,pointCheck,setXData,setYData,setMaxChecked) => {
        
        const countCopyY = [...yData];
        const countCheckY = countCopyY.filter((countCopyY) => countCopyY.check === true).length;
        const countCopyX = [...xData];
        const countCheckX = countCopyX.filter((countCopyX) => countCopyX.check === true).length;
        const checkedListCopy = [...checkedList];
        let totalCount = countCheckX + countCheckY + checkedListCopy.length;
        if (pointCheck === false) {
            totalCount = totalCount + 1;
        } else {
            totalCount = totalCount - 1;
        };
        
        
        if (totalCount > 1) {
            setMaxChecked(true)
            setXData(value => value.map((item, index)=> {
                const newItem = {...item}

                
                if (item.check === true) {
                    newItem.disabled = false
                    return newItem
                } else if (item.check === false) {
                    newItem.disabled = true
                    return newItem
                } else {
                    return item
            }}))

            setYData(value => value.map((item, index)=> {
                const newItem = {...item}

                if (item.check === true) {                    
                    newItem.disabled = false
                    return newItem
                } else if (item.check === false) {
                    newItem.disabled = true                   
                    return newItem
                } else {
                    return item
            }}))
        } else {
            setMaxChecked(false)
            setXData(value => value.map((item, index)=> {
                
                if (item.disabled === true) {
                    return {ind: item.ind, val : item.val, check: item.check, disabled: false} 
                } else {
                    
                    return item
            }}))

            setYData(value => value.map((item, index)=> {


                if (item.disabled === true) {
                    return {ind: item.ind, val : item.val, check: item.check, disabled: false} 
                } else {
                    
                    return item
            }}))    
            
        }
    }

    const handleCheckFlowers09 = (e,xData,yData,setXData,setYData,setMaxChecked,checkedList, setCheckedList) => {
        let pointCheck = e.target.checked ? false : true
        if (e.target.checked ===true) {
            setCheckedList(checkedList => [...checkedList,e.target.value]);
        } else {
            setCheckedList(checkedList.filter(value => value!==e.target.value));
        } 
        isCheckDisabled(xData,yData,checkedList,pointCheck,setXData,setYData,setMaxChecked)     
    };

    export {handleCheckFlowers09, handleCheckX, handleCheckY}