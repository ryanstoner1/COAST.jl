import React, { useEffect, useState, useRef } from 'react';
import axios from "axios";
import PropTypes from 'prop-types';
import Highcharts from 'highcharts/highcharts';
import HighchartsReact from 'highcharts-react-official';
import addExporting from "highcharts/modules/exporting";
import moreExporting from "highcharts/modules/export-data";
addExporting(Highcharts);
moreExporting(Highcharts);
var HC_more = require('highcharts/highcharts-more');
var Dragable = require("highcharts/modules/draggable-points")(Highcharts);



/**
 * ExampleComponent is an example component.
 * It takes a property, `label`, and
 * displays it.
 * It renders an input with the property `value`
 * which is editable by the user.
 */
export default function CoastApp(props) {


    const initx1 = 10.0
    const inity1 = 20.0
    const initP1 = [{ x: initx1, y: inity1 }]

    const chartRef = useRef();
    const { id, label, setProps, value, 
        Etrap, 
        alpha,
        c0,
        c1, 
        c2,
        c3,
        rmr0,
        eta_q,
        L_dist, 
        psi,
        omega,
        E_L,
        D0L_a2,
        rad,
        u38,
        th32,        
         } = props;
    const initData = JSON.parse(label)
    const [plotData, setPlotData] = useState(initData);
    const [ids, setIds] = useState([1]);

    const [juliadate, setJuliadate] = useState(0.0);
    const handlePointClick = (e) => {
        const chartLocal = chartRef.current.chart;
        chartLocal.series[0].removePoint(e.point.index);

        const asyncFunc = async () => {
            try {
              // fetch data from a url endpoint
              const response = await axios.post('http://localhost:8000/', {
                name: "[3.0,4.0]",
              });
              console.log(response.data);
            } catch (error) {
              console.log("error", error);
              // appropriately handle the error
            }
        };
        setProps({ label: JSON.stringify(chartLocal.series[0].xData) })
    };

    const handlePointDrag = (e) => {
        const asyncFunc = async () => {
            try {
              // fetch data from a url endpoint
              const response = await axios.post('http://localhost:8000/', {
                name: "[3.0,4.0]",
              });
              console.log(response.data);
            } catch (error) {
              console.log("error", error);
              // appropriately handle the error
            }
        };

        const chartLocal = chartRef.current.chart;
        setProps({ label: JSON.stringify(chartLocal.series[0].xData) })
    };

    const handleChartClick = (e) => {
        const chartLocal = chartRef.current.chart;
        chartLocal.series[0].addPoint({ x: e.xAxis[0].value, y: e.yAxis[0].value });
        
        const asyncFunc = async () => {
            try {
              // fetch data from a url endpoint
              const response = await axios.post('http://localhost:8000/', {
                name: "[3.0,4.0]",
              });
              console.log(response.data);
            } catch (error) {
              console.log("error", error);
              // appropriately handle the error
            }
        };
        setProps({ label: JSON.stringify(chartLocal.series[0].xData) })
    };

    const [options, setOptions] = useState({
        tooltip: { enabled: false },
        title: {
            text: 'Temperature-Time Path',
            align: 'center'
        },
        xAxis: {
            title: { text: "time (Ma)" },
            min: 0,
            max: 400,
            reversed: true
        },
        yAxis: {
            gridLineWidth: 0,
            min: 0,
            max: 400,
            title: { text: "temperature (ºC)" },
            reversed: true
        },
        series: [
            {
                showInLegend: false,
                dragDrop: {
                    draggableY: true,
                    draggableX: true
                },
                data: initP1,
            }
        ],
        chart: {
            plotBorderWidth: 2,
            animation: {
                duration: 10
            },
            events: {
                click: (e) => {
                    handleChartClick(e);
                }
            }
        },
        exporting: {
            chartOptions: {
                plotOptions: {
                    series: {
                        dataLabels: {
                            enabled: true
                        }
                    }
                }
            }
        },
        plotOptions: {
            series: {
                allowPointSelect: false,
                connectNulls: true,
                point: {
                    events: {
                        drag: (e) => {
                            handlePointDrag(e)
                        },
                        click: (e) => {
                            handlePointClick(e)
                        },
                    }
                }
            }
        }
    });

    // delete last point in series with backspace
    const handleKeyDown = (event) => {
        
        const deleteKey = 88
        const chartLocal = chartRef.current.chart;

        if (event.keyCode === deleteKey) {
            chartLocal.series[0].setData(options.series[0].data.filter((element, index) => {
                
                return (index !== (options.series[0].data.length - 1))
            }));
        }
        //console.log(JSON.stringify(options.series[0].data))
        const rawData = JSON.stringify(options.series[0].data)
        console.log(rawData)
        axios.post('http://localhost:8000/model', {
            name: 'Finn',
            function_to_run: 'single_grain',
            Etrap: Etrap,
            alpha: alpha,
            c0: c0,
            c0: c0,
            c1: c1,
            c2: c2,
            c3: c3,
            rmr0: rmr0,
            eta_q: eta_q, 
            L_dist: L_dist,
            psi: psi,
            omega: omega,
            E_L: E_L,
            D0L_a2: D0L_a2,
            rad: rad,
            u38: u38,
            th32: th32,
            tT: rawData,
        }).then((response) => {
            console.log(response.data);
          }, (error) => {
            console.log(error);
        });
    };

    useEffect(() => {
        window.addEventListener('keydown', handleKeyDown);

        // cleanup this component
        return () => {
            window.removeEventListener('keydown', handleKeyDown);
        };
    }, []);

    return (
        <div id={id}>
            <div>
                <HighchartsReact
                    highcharts={Highcharts}
                    options={options}
                    ref={chartRef}
                />
            </div>
            <p>Date (Ma): {juliadate}</p>
            ExampleComponent: {label}&nbsp;
            <input
                value={value}
                onChange={
                    /*
                        * Send the new value to the parent component.
                        * setProps is a prop that is automatically supplied
                        * by dash's front-end ("dash-renderer").
                        * In a Dash app, this will update the component's
                        * props and send the data back to the Python Dash
                        * app server if a callback uses the modified prop as
                        * Input or State.
                    */
                    e => {
                        setProps({ value: e.target.value });
                        
                }
                }
            />
        </div>
    );
}



CoastApp.defaultProps = {};

CoastApp.propTypes = {
    /**
     * The ID used to identify this component in Dash callbacks.
     */
    id: PropTypes.string,

    /**
     * A label that will be printed when this component is rendered.
     */
    label: PropTypes.string.isRequired,

    /**
     * The value displayed in the input.
     */
    value: PropTypes.string,

    /**
     * The value displayed in the input.
     */
    rad:  PropTypes.string,

    /**
     * The value displayed in the input.
     */
    u38:  PropTypes.string,    

    /**
     * The value displayed in the input.
     */
    th32:  PropTypes.string,  

    /**
     * The value displayed in the input.
     */
    Etrap: PropTypes.string,

    /**
     * The value displayed in the input.
     */
    alpha:  PropTypes.string,

    /**
     * The value displayed in the input.
     */
    c0:  PropTypes.string,


    /**
     * The value displayed in the input.
     */
    c1:  PropTypes.string,
    
    
    /**
     * The value displayed in the input.
     */
    c2:  PropTypes.string,


    /**
     * The value displayed in the input.
     */
    c3:  PropTypes.string,


    /**
     * The value displayed in the input.
     */
    rmr0: PropTypes.string,


    /**
     * The value displayed in the input.
     */
    eta_q:  PropTypes.string,


    /**
     * The value displayed in the input.
     */
    L_dist:  PropTypes.string,
    
    
    /**
     * The value displayed in the input.
     */
    psi:  PropTypes.string,


    /**
     * The value displayed in the input.
     */
    omega:  PropTypes.string,


    /**
     * The value displayed in the input.
     */
    E_L:  PropTypes.string,


    /**
     * The value displayed in the input.
     */
    D0L_a2:  PropTypes.string,

    /**
     * Dash-assigned callback that should be called to report property changes
     * to Dash, to make them available for callbacks.
     */
    setProps: PropTypes.func
};
