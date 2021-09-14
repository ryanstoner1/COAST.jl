import {InputGroup, FormControl} from 'react-bootstrap';
import {handletMin, handletMax, handleTMin, handleTMax} from './manualBoundEditing.js';
import { handleCheckt, handleCheckT } from './handleChecking.js';

const TimeDataCheckList = ({tData, TData, settData, setTData, checkedList,setMaxChecked, chartRef}) => {
    return (
        <div>
        { (tData.length) ? 
            <div>
                <br></br>
                {tData.map((point, index) => (
                    <div key={index}>
                        <InputGroup className="mb-3">
                        <InputGroup.Prepend>
                        <InputGroup.Text type="checkbox" >
                        <div>
                            varying <i>time</i> at point {index+1} at time {Math.round((point.val[1].x + Number.EPSILON) * 10) / 10} Ma (min/max)
                        </div>
                        <div>
                            &nbsp;
                        </div>
                        <input type="checkbox" id="vehicle1" name="vehicle1" disabled={point.disabled} value={[index,"x"]} onChange={(e) => handleCheckt(e,point.ind,point.check,tData,TData,settData,setTData,checkedList,setMaxChecked)} checked={point.check}/>
                        </InputGroup.Text>
                        </InputGroup.Prepend>
                        <FormControl type="number" placeholder={`min: ${Math.round((point.val[0].x + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handletMin(e,point.ind,chartRef,settData)}/>
                        <FormControl type="number" placeholder={`max: ${Math.round((point.val[2].x + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handletMax(e,point.ind,chartRef,settData)}/>
                        </InputGroup>                            
                    </div>
                )
                )}
        </div> : null}
        </div>
    );
};

const TempDataCheckList = ({tData, TData, settData, setTData, checkedList,setMaxChecked, chartRef}) => { 
    return (
        <div>
        { (TData.length) ? 
            <div>
                {TData.map((point, index) => (
                    <div key={index}>
                        <InputGroup className="mb-3">
                        <InputGroup.Prepend>
                        <InputGroup.Text type="checkbox" >
                        <div>
                            varying <i>temperature </i> at point {index+1} at temperature {Math.round((point.val[1].y + Number.EPSILON) * 10) / 10} ºC (min/max)
                        </div>
                        <div>
                            &nbsp;
                        </div>
                        <input type="checkbox" id="vehicle1" name="vehicle1" disabled={point.disabled} value={[index,"y"]} onChange={(e) => handleCheckT(e,point.ind,point.check,tData,TData,settData,setTData,checkedList,setMaxChecked)} checked={point.check}/>
                        </InputGroup.Text>
                        </InputGroup.Prepend>
                        <FormControl type="number" placeholder={`min: ${Math.round((point.val[0].y + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleTMin(e,point.ind,chartRef,setTData)}/>
                        <FormControl type="number" placeholder={`max: ${Math.round((point.val[2].y + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleTMax(e,point.ind,chartRef,setTData)}/>
                        </InputGroup>                            
                    </div>
                )
                )}
            </div> : null}
        </div>
    );       
};
export {TimeDataCheckList, TempDataCheckList}