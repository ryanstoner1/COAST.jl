import {InputGroup, FormControl} from 'react-bootstrap';
import {handleXMin, handleXMax, handleYMin, handleYMax} from './manualBoundEditing.js';
import { handleCheckX, handleCheckY } from './handleChecking.js';

const XDataCheckList = ({xData, yData, setXData, setYData, checkedList,setMaxChecked, chartRef}) => {
    return (
        <div>
        { (xData.length) ? 
            <div>
                <br></br>
                {xData.map((point, index) => (
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
                        <input type="checkbox" id="vehicle1" name="vehicle1" disabled={point.disabled} value={[index,"x"]} onChange={(e) => handleCheckX(e,point.ind,point.check,xData,yData,setXData,setYData,checkedList,setMaxChecked)} checked={point.check}/>
                        </InputGroup.Text>
                        </InputGroup.Prepend>
                        <FormControl type="number" placeholder={`min: ${Math.round((point.val[0].x + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleXMin(e,point.ind,chartRef)}/>
                        <FormControl type="number" placeholder={`max: ${Math.round((point.val[2].x + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleXMax(e,point.ind,chartRef)}/>
                        </InputGroup>                            
                    </div>
                )
                )}
        </div> : null}
        </div>
    );
};

const YDataCheckList = ({xData, yData, setXData, setYData, checkedList,setMaxChecked, chartRef}) => { 
    return (
        <div>
        { (yData.length) ? 
            <div>
                {yData.map((point, index) => (
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
                        <input type="checkbox" id="vehicle1" name="vehicle1" disabled={point.disabled} value={[index,"y"]} onChange={(e) => handleCheckY(e,point.ind,point.check,xData,yData,setXData,setYData,checkedList,setMaxChecked)} checked={point.check}/>
                        </InputGroup.Text>
                        </InputGroup.Prepend>
                        <FormControl type="number" placeholder={`min: ${Math.round((point.val[0].y + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleYMin(e,point.ind,chartRef)}/>
                        <FormControl type="number" placeholder={`max: ${Math.round((point.val[2].y + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleYMax(e,point.ind,chartRef)}/>
                        </InputGroup>                            
                    </div>
                )
                )}
            </div> : null}
        </div>
    );       
};
export {XDataCheckList, YDataCheckList}