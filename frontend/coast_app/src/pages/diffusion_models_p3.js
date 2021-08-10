import {React, useState, useEffect} from 'react';
import {InputGroup, FormControl, Button, Alert} from 'react-bootstrap';
import axios from 'axios';

const Diff = ({ chartRef, xData, yData, checkedList, maxChecked, onCheckChange, setIsChartXY, setDataXY, radioValue} ) => {
    const [warnEmpty, setWarnEmpty] = useState(false)
    const [warnNonInt, setWarnNonInt] = useState(false)
    const [warnCheckedBad, setWarnCheckedBad] = useState(false)
    const [numberX, setNumberX] = useState("")
    const [numberZ, setNumberZ] = useState("")
    const [U238, setU238] = useState({main: '', min: '', max: ''})
    const [Th232, setTh232] = useState({main: '', min: '', max: ''})
    const [Ea, setEa] = useState({main: 122.3, min: '', max: ''})
    const [rad, setRad] = useState({main: '', min: '', max: ''})
    const [D0, setD0] = useState({main: 9.733, min: '', max: ''})
    const [rmr0, setRmr0] = useState({main: 0.81, min: '', max: ''})
    const [alpha, setAlpha] = useState({main: 0.04672, min: '', max: ''})
    const [c0Value, setC0Value] = useState({main: 0.39528, min: '', max: ''})
    const [c1Value, setC1Value] = useState({main: 0.01073, min: '', max: ''})
    const [c2Value, setC2Value] = useState({main: -65.12969, min: '', max: ''})
    const [c3Value, setC3Value] = useState({main: -7.91715, min: '', max: ''})
    const [Letch, setLetch] = useState({main: 8.1, min: '', max: ''})
    const [etaq, setEtaq] = useState({main: 0.91, min: '', max: ''})
    const [psi, setPsi] = useState({main: 1e-13, min: '', max: ''})
    const [omega, setOmega] = useState({main: 1e-22, min: '', max: ''})
    const [etrap, setEtrap] = useState({main: 34, min: '', max: ''})
    // const [juliaResponse, setJuliaResponse] = useState({})

    const handleProcess = (e, radioVal) => {
        const formInit = {
            function_to_run: "store_params",
            numberX: JSON.parse(JSON.stringify(numberX)),
            numberZ: JSON.parse(JSON.stringify(numberZ)),
            Letch: JSON.parse(JSON.stringify(Letch)),
            U238: U238,
            Th232: Th232,
            Ea: Ea,
            rad: rad,
            D0: D0,
            rmr0: rmr0,
            alpha: alpha,
            c0Value: c0Value,
            c1Value: c1Value,
            c2Value: c2Value,
            c3Value: c3Value,
            etaq: etaq,
            psi: psi,
            omega: omega,
            etrap: etrap,
            userIP: undefined,
        };

        const xDataCopy = [...xData];
        const yDataCopy = [...yData];
        xDataCopy.forEach((value,ind)=>{
            // makes the processing easier on the python side
            const newKeyString = "xData".concat(ind.toString())
            formInit[newKeyString] = {min: value.val[0].x, main: value.val[1].x, max: value.val[2].x}
        });
        yDataCopy.forEach((value,ind)=>{
            // makes the processing easier on the python side
            const newKeyString = "yData".concat(ind.toString())
            formInit[newKeyString] = {min: value.val[0].y, main: value.val[1].y, max: value.val[2].y}
        });

        formInit["xSeries"] = [...chartRef.current.chart.series[0].xData]
        formInit["ySeries"] = [...chartRef.current.chart.series[0].yData]
        const formXYPlot = {
                userIP: undefined,
                xData: xDataCopy,
                yData: yDataCopy,
                xSeries: [...chartRef.current.chart.series[0].xData],
                ySeries: [...chartRef.current.chart.series[0].yData],
                checkedList: checkedList,
                function_to_run: "run_xy_flowers09",
        }

        if (radioVal==="1") {
            if (numberX==="") {
                setWarnEmpty(true)
            } else if (Number.isInteger(parseFloat(numberX))===false) {
                setWarnNonInt(true)
            } else if (checkedList.length>0){
                const checkedListCopy = [...checkedList];
                checkedListCopy.forEach(value=>{
                    if ((formInit[value].min==="")| (formInit[value].max==="")) {
                        setWarnCheckedBad(true) 
                    } else {
                        setWarnCheckedBad(false) 
                    }
                })
                if (warnCheckedBad===false) {
                    axios.get("http://127.0.0.1:5000/get_coast_ip")
                    .then((res) => {
                        formInit.userIP = res.data.ip; 
                        console.log(formInit)           
                        return axios.post("http://0.0.0.0:8000/model", formInit)                       
                    }).then(res=> {
                        formXYPlot.userIP = formInit.userIP;
                        return axios.post("http://0.0.0.0:8000/model", formXYPlot)           
                    }).then(res=>{
                        setIsChartXY(true)
                        const dataout = res.data[0]
                        const xout = res.data[1]
                        const len_xout = xout.length

                        let dataHighChartsXY = [];
                        const new_row = [];
                        dataout.forEach((value,ind) => {
                            let mod_xout = ind % len_xout                          
                            new_row.push({x: xout[mod_xout], y: value})
                            if (mod_xout===(len_xout-1)) {
                                dataHighChartsXY.push([...new_row])
                                new_row.length = 0
                            }
                        })
                        console.log(dataHighChartsXY)
                        setDataXY(dataHighChartsXY)
                    }).catch(err => console.warn(err));                
                }
            } else {
                axios.get("http://127.0.0.1:5000/get_coast_ip")
                .then((res) => {
                    formInit.userIP = res.data.ip;            
                    return axios.post("http://0.0.0.0:8000/model", formInit)                       
                }).then(res=> {
                    formXYPlot.userIP = formInit.userIP;
                    return axios.post("http://0.0.0.0:8000/model", formXYPlot)           
                }).then(res=>{
                    setIsChartXY(true)
                    console.log(res.data)
                    
                    const dataHighchartsXY = res.data.map(value=>{
                        return value.map((value_inner,ind)=>{
                            const returnval = {x:chartRef.current.chart.series[0].xData[ind], y:value_inner }
                            console.log(returnval)
                            return returnval
                        })
                    })
                    setDataXY(dataHighchartsXY)
                }).catch(err => console.warn(err));
            }            
        } else {
            const formData = new FormData();

            formData.append("param1",JSON.stringify(formInit));   
            const config = {     
                headers: { 'content-type': 'application/json' }
            }
            axios
            .post("http://127.0.0.1:5000/getPCE", formData, config)
            .then(res => console.log(res))
            .catch(err => console.warn(err))
        }
        };

        // get rid of warnings when user modifies previously incorrect entry
        useEffect(value=>{
            setWarnEmpty(false)
            setWarnNonInt(false)
        },[numberX,numberZ])


    return(
    <div>
    <Button variant="outline-primary" onClick={e => handleProcess(e,radioValue)}>Start sensitivity analysis</Button>
    <br></br>
    <br></br>
    { warnEmpty ? <Alert variant={"warning"}>COAST  was unable to process data! Set the number of time-temperature (t-T) paths to solve for before processing.</Alert> : null}
    { warnNonInt ? <Alert variant={"warning"}>COAST was unable to process data! Non-integer input. Set to whole (positive) number before processing.</Alert> : null}
    <br></br>
    { warnCheckedBad ? <Alert variant={"warning"}>COAST was unable to process data! Enter range of diffusion constant values to checked values before processing. </Alert> : null}
    <br></br>
    <h5>Setup</h5>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-npaths">number tT<sub>paths </sub><div>&nbsp;</div><input type="checkbox"   value=" Bike"/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" placeholder="n runs x axis (<100,000 single grain, <15,000 profile)" type="number" value={numberX} onInput={e => setNumberX(e.target.value)}/>
        <FormControl aria-label="Text input with checkbox" placeholder="n runs countour (<100,000 single grain, <15,000 profile)" type="number" value={numberZ} onInput={e => setNumberZ(e.target.value)}/>
    </InputGroup>                    
    <h5>Diffusion parameters</h5>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-ea">U<sub>238 </sub><div>&nbsp;</div><input type="checkbox"   value="U238" disabled={maxChecked ? !(checkedList.includes("U238")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" placeholder="ppm" type="number" value={U238.main} onInput={e => setU238({...U238,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={U238.min} onInput={e => setU238({...U238,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max"type="number" value={U238.max} onInput={e => setU238({...U238,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-r">Th<sub>232 </sub><div>&nbsp;</div><input type="checkbox"   value="Th232" disabled={maxChecked ? !(checkedList.includes("Th232")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" placeholder="ppm" value={Th232.main} onInput={e => setTh232({...Th232,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox"  placeholder="min" type="number" value={Th232.min} onInput={e => setTh232({...Th232,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox"  placeholder="max"type="number" value={Th232.max} onInput={e => setTh232({...Th232,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-ea">E<sub>a </sub><div>&nbsp;</div><input type="checkbox"   value="Ea" disabled={maxChecked ? !(checkedList.includes("Ea")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" placeholder="kJ" value={Ea.main} onInput={e => setEa({...Ea,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={Ea.min} onInput={e => setEa({...Ea,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={Ea.max} onInput={e => setEa({...Ea,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-r">rad<div>&nbsp;</div><input type="checkbox"   value="rad" disabled={maxChecked ? !(checkedList.includes("rad")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox"  value={rad.main} onInput={e => setRad({...rad,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={rad.min} onInput={e => setRad({...rad,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={rad.max} onInput={e => setRad({...rad,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">D<sub>0 </sub><div>&nbsp;</div><input type="checkbox"   value="D0" disabled={maxChecked ? !(checkedList.includes("D0")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox"  value={D0.main} onInput={e => setD0({...D0,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={D0.min} onInput={e => setD0({...D0,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={D0.max} onInput={e => setD0({...D0,max: e.target.value})}/>
    </InputGroup>
    <h5>Radiation damage parameters</h5>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">rmr<sub>0</sub><div>&nbsp;</div><input type="checkbox"   value="rmr0" disabled={maxChecked ? !(checkedList.includes("rmr0")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={rmr0.main} onInput={e => setRmr0({...rmr0,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={rmr0.min} onInput={e => setRmr0({...rmr0,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={rmr0.max} onInput={e => setRmr0({...rmr0,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">E<sub>trap</sub><div>&nbsp;</div><input type="checkbox"   value="etrap" disabled={maxChecked ? !(checkedList.includes("etrap")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={etrap.main} onInput={e => setEtrap({...etrap,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={etrap.min} onInput={e => setEtrap({...etrap,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={etrap.max} onInput={e => setEtrap({...etrap,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">&#945;<div>&nbsp;</div><input type="checkbox"   value="alpha" disabled={maxChecked ? !(checkedList.includes("alpha")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={alpha.main} onInput={e => setAlpha({...alpha,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={alpha.min} onInput={e => setAlpha({...alpha,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max"type="number" value={alpha.max} onInput={e => setAlpha({...alpha,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">c<sub>0</sub><div>&nbsp;</div><input type="checkbox"   value="c0Value" disabled={maxChecked ? !(checkedList.includes("c0Value")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={c0Value.main} onInput={e => setC0Value({...c0Value,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={c0Value.min} onInput={e => setC0Value({...c0Value,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={c0Value.max} onInput={e => setC0Value({...c0Value,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">c<sub>1</sub><div>&nbsp;</div><input type="checkbox"   value="c1Value" disabled={maxChecked ? !(checkedList.includes("c1Value")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={c1Value.main} onInput={e => setC1Value({...c1Value,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={c1Value.min} onInput={e => setC1Value({...c1Value,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={c1Value.max} onInput={e => setC1Value({...c1Value,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">c<sub>2</sub><div>&nbsp;</div><input type="checkbox"   value="c2Value" disabled={maxChecked ? !(checkedList.includes("c2Value")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={c2Value.main} onInput={e => setC2Value({...c2Value,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={c2Value.min} onInput={e => setC2Value({...c2Value,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={c2Value.max} onInput={e => setC2Value({...c2Value,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">c<sub>3</sub><div>&nbsp;</div><input type="checkbox"   value="c3Value" disabled={maxChecked ? !(checkedList.includes("c3Value")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={c3Value.main} onInput={e => setC3Value({...c3Value,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={c3Value.min} onInput={e => setC3Value({...c3Value,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={c3Value.max} onInput={e => setC3Value({...c3Value,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-letch">L<sub>etch</sub><div>&nbsp;</div><input type="checkbox"   value="Letch" disabled={maxChecked ? !(checkedList.includes("Letch")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={Letch.main} onInput={e => setLetch({...Letch,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={Letch.min} onInput={e => setLetch({...Letch,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={Letch.max} onInput={e => setLetch({...Letch,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">&#951;q<div>&nbsp;</div><input type="checkbox"   value="etaq" disabled={maxChecked ? !(checkedList.includes("etaq")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={etaq.main} onInput={e => setEtaq({...etaq,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={etaq.min} onInput={e => setEtaq({...etaq,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={etaq.max} onInput={e => setEtaq({...etaq,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3"> 
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">&#936;<div>&nbsp;</div><input type="checkbox"   value="psi" disabled={maxChecked ? !(checkedList.includes("psi")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={psi.main} onInput={e => setPsi({...psi,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={psi.min} onInput={e => setPsi({...psi,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={psi.max} onInput={e => setPsi({...psi,max: e.target.value})}/>
    </InputGroup>
    <InputGroup className="mb-3">
        <InputGroup.Prepend>
        <InputGroup.Text id="inputGroup-d0">&#937;<div>&nbsp;</div><input type="checkbox"   value="omega" disabled={maxChecked ? !(checkedList.includes("omega")) : false} onChange={(e) => onCheckChange(e,xData,yData,checkedList)}/></InputGroup.Text>
        </InputGroup.Prepend>
        <FormControl aria-label="Text input with checkbox" value={omega.main} onInput={e => setOmega({...omega,main: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="min" type="number" value={omega.min} onInput={e => setOmega({...omega,min: e.target.value})}/>
        <FormControl aria-label="Text input with checkbox" placeholder="max" type="number" value={omega.max} onInput={e => setOmega({...omega,max: e.target.value})}/>
    </InputGroup>
    </div>
    );
};
export default Diff