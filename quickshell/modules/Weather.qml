import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.commonwidgets
import qs.theme as T

BarIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: false
    fontPixelSize: T.Config.fontSizeNormal
    verticalPadding: T.Config.popupPadding + T.Config.barIconSize - fontPixelSize
    iconText: weatherIcon + (temperature ? " " + temperature : "")

    property string weatherIcon: ""
    property string temperature: ""
    property string condition: "Loading"
    property string location: ""
    property string feelsLike: ""
    property string humidity: ""
    property string wind: ""
    property var forecast: []

    function iconForCode(code) {
        const c = parseInt(String(code || "0"), 10);
        switch (c) {
        case 113: return "";
        case 116: return "";
        case 119: case 122: return "";
        case 143: case 248: case 260: return "";
        case 176: case 263: case 353: return "";
        case 179: case 227: case 230: case 323: case 326: case 368: return "";
        case 182: case 185: case 281: case 284: case 311: case 314:
        case 317: case 320: case 350: case 362: case 365: case 374: case 377: return "";
        case 200: case 386: case 389: case 392: case 395: return "";
        case 266: case 293: case 296: case 299: case 302: case 305: case 308: case 356: case 359: return "";
        case 329: case 332: case 335: case 338: case 371: return "";
        default: return "";
        }
    }

    function iconForOpenMeteoCode(code) {
        const c = parseInt(String(code || "0"), 10);
        if (c === 0) return iconForCode(113);
        if (c === 1 || c === 2) return iconForCode(116);
        if (c === 3) return iconForCode(119);
        if (c === 45 || c === 48) return iconForCode(143);
        if (c === 51 || c === 53 || c === 55 || c === 56 || c === 57 || c === 61) return iconForCode(266);
        if (c === 63 || c === 65 || c === 66 || c === 67 || c === 80 || c === 81 || c === 82) return iconForCode(308);
        if (c === 71 || c === 73 || c === 75 || c === 77 || c === 85 || c === 86) return iconForCode(338);
        if (c === 95 || c === 96 || c === 99) return iconForCode(389);
        return iconForCode(119);
    }

    function fetchForecast(latitude, longitude) {
        if (forecastProc.running || latitude === "" || longitude === "") return;

        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + encodeURIComponent(latitude)
            + "&longitude=" + encodeURIComponent(longitude)
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&forecast_days=4"
            + "&temperature_unit=fahrenheit"
            + "&timezone=auto";
        forecastProc.command = ["curl", "-fsS", "--max-time", "5", url];
        forecastProc.running = true;
    }

    function refresh() {
        if (!weatherProc.running) {
            weatherProc.running = true;
        }
    }

    Process {
        id: weatherProc
        command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/?format=j1"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const report = JSON.parse(text);
                    const current = report.current_condition && report.current_condition[0];
                    const area = report.nearest_area && report.nearest_area[0];
                    if (!current) return;

                    root.weatherIcon = root.iconForCode(current.weatherCode);
                    root.temperature = current.temp_F + "°";
                    root.condition = current.weatherDesc && current.weatherDesc[0] ? current.weatherDesc[0].value : "Current weather";
                    root.location = area && area.areaName && area.areaName[0] ? area.areaName[0].value : "";
                    root.feelsLike = current.FeelsLikeF + "°";
                    root.humidity = current.humidity + "%";
                    root.wind = current.windspeedMiles + " mph";

                    if (area) {
                        root.fetchForecast(area.latitude || "", area.longitude || "");
                    }
                } catch (e) {
                    console.log("weather parse error:", e, text);
                }
            }
        }
    }

    Process {
        id: forecastProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const report = JSON.parse(text);
                    const daily = report.daily;
                    if (!daily || !daily.time) return;

                    const days = [];
                    for (let i = 0; i < Math.min(4, daily.time.length); i++) {
                        days.push({
                            date: daily.time[i],
                            icon: root.iconForOpenMeteoCode(daily.weather_code[i]),
                            high: Math.round(daily.temperature_2m_max[i]) + "°",
                            low: Math.round(daily.temperature_2m_min[i]) + "°"
                        });
                    }
                    root.forecast = days;
                } catch (e) {
                    console.log("forecast parse error:", e, text);
                }
            }
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
