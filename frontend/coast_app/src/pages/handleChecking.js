
    const handleCheckt = (e,pointInd,pointCheck,tData,TData,settData,setTData,checkedList,setMaxChecked) => {

        settData(value => value.map(item=> {
            if (item.ind === pointInd & item.check === true) {
                return {ind: pointInd, val : [...item.val], check: false, disabled: item.disabled} 
            } else if (item.ind === pointInd & item.check === false) {
                return {ind: pointInd, val : [...item.val], check: true, disabled: item.disabled} 
            } else {
                return item
            }}))
        isCheckDisabled(tData,TData,checkedList,pointCheck,settData,setTData,setMaxChecked)
    };

    const handleCheckT = (e,pointInd,pointCheck,tData,TData,settData,setTData,checkedList,setMaxChecked) => {    
        setTData(value => value.map(item=> {
            
            if (item.ind === pointInd & item.check === true) {

                return {ind: pointInd, val : [...item.val], check: false, disabled: item.disabled} 
            } else if (item.ind === pointInd & item.check === false) {

                return {ind: pointInd, val : [...item.val], check: true, disabled: item.disabled} 
            } else {
                return item
            }}))
        isCheckDisabled(tData,TData,checkedList,pointCheck,settData,setTData,setMaxChecked)
    };

    const isCheckDisabled = (tData,TData,checkedList,pointCheck,settData,setTData,setMaxChecked) => {
        
        const countCopyZ = [...TData];
        const countCheckZ = countCopyZ.filter((countCopyZ) => countCopyZ.check === true).length;
        const countCopyX = [...tData];
        const countCheckX = countCopyX.filter((countCopyX) => countCopyX.check === true).length;
        const checkedListCopy = [...checkedList];
        let totalCount = countCheckX + countCheckZ + checkedListCopy.length;
        if (pointCheck === false) {
            totalCount = totalCount + 1;
        } else {
            totalCount = totalCount - 1;
        };
        
        
        if (totalCount > 1) {
            setMaxChecked(true)
            settData(value => value.map((item, index)=> {
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

            setTData(value => value.map((item, index)=> {
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
            settData(value => value.map((item, index)=> {
                
                if (item.disabled === true) {
                    return {ind: item.ind, val : item.val, check: item.check, disabled: false} 
                } else {
                    
                    return item
            }}))

            setTData(value => value.map((item, index)=> {


                if (item.disabled === true) {
                    return {ind: item.ind, val : item.val, check: item.check, disabled: false} 
                } else {
                    
                    return item
            }}))    
            
        }
    }

    const handleCheckFlowers09 = (e,tData,TData,settData,setTData,setMaxChecked,checkedList, setCheckedList) => {
        let pointCheck = e.target.checked ? false : true
        if (e.target.checked ===true) {
            setCheckedList(checkedList => [...checkedList,e.target.value]);
        } else {
            setCheckedList(checkedList.filter(value => value!==e.target.value));
        } 
        isCheckDisabled(tData,TData,checkedList,pointCheck,settData,setTData,setMaxChecked)     
    };

    export {handleCheckFlowers09, handleCheckt, handleCheckT}