import React, { useEffect, useState, useRef } from 'react';
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
    const initP1 = { x: initx1, y: inity1 }

    const chartRef = useRef();
    const { id, label, setProps, value } = props;
    const initData = JSON.parse(label)
    const [plotData, setPlotData] = useState(initData);
    const [ids, setIds] = useState([1]);

    const handlePointClick = (e) => {
        const chartLocal = chartRef.current.chart;
        chartLocal.series[0].removePoint(e.point.index);
        setProps({ label: JSON.stringify(chartLocal.series[0].xData) })
    };

    const handlePointDrag = (e) => {
        const chartLocal = chartRef.current.chart;
        setProps({ label: JSON.stringify(chartLocal.series[0].xData) })
    };

    const handleChartClick = (e) => {
        const chartLocal = chartRef.current.chart;
        chartLocal.series[0].addPoint({ x: e.xAxis[0].value, y: e.yAxis[0].value });
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
                data: initData,
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
                    e => setProps({ value: e.target.value })
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
     * Dash-assigned callback that should be called to report property changes
     * to Dash, to make them available for callbacks.
     */
    setProps: PropTypes.func
};
