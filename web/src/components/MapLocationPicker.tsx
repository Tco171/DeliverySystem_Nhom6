import { useEffect, useRef } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import "./MapLocationPicker.css";

export type MapCoordinate = { latitude: number; longitude: number };
type Props = {
  label: string;
  value: MapCoordinate | null;
  onChange: (coordinate: MapCoordinate) => void;
  color?: string;
};

const DEFAULT_CENTER: L.LatLngExpression = [10.7769, 106.7009];

export default function MapLocationPicker({ label, value, onChange, color = "#e65520" }: Props) {
  const elementRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markerRef = useRef<L.CircleMarker | null>(null);
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;

  useEffect(() => {
    if (!elementRef.current || mapRef.current) return;
    const map = L.map(elementRef.current, { scrollWheelZoom: false }).setView(
      value ? [value.latitude, value.longitude] : DEFAULT_CENTER,
      value ? 15 : 12,
    );
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);
    map.on("click", (event: L.LeafletMouseEvent) => {
      onChangeRef.current({ latitude: Number(event.latlng.lat.toFixed(7)), longitude: Number(event.latlng.lng.toFixed(7)) });
    });
    mapRef.current = map;
    window.setTimeout(() => map.invalidateSize(), 0);
    return () => {
      map.remove();
      mapRef.current = null;
      markerRef.current = null;
    };
    // Map is created once; the selected value is synced by the next effect.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    if (!value) {
      if (markerRef.current) markerRef.current.remove();
      markerRef.current = null;
      return;
    }
    const point: L.LatLngExpression = [value.latitude, value.longitude];
    if (!markerRef.current) {
      markerRef.current = L.circleMarker(point, { radius: 9, color, fillColor: color, fillOpacity: 0.9 }).addTo(map);
    } else {
      markerRef.current.setLatLng(point).setStyle({ color, fillColor: color });
    }
    map.panTo(point);
  }, [value, color]);

  return <section className="map-picker">
    <div className="map-picker__heading"><strong>{label}</strong><span>Nhấn vào bản đồ để chọn vị trí</span></div>
    <div className="map-picker__map" ref={elementRef} />
    <div className="map-picker__coordinates">
      {value ? <>Vĩ độ: <code>{value.latitude}</code> · Kinh độ: <code>{value.longitude}</code></> : "Chưa chọn vị trí"}
    </div>
  </section>;
}
