import Network

/// Avisa ante cualquier cambio en la configuración de red (pasar de Wi-Fi a
/// cable o viceversa, conectar/desconectar, cambio de IP, etc.) para poder
/// refrescar los datos al instante, sin depender del intervalo configurado.
final class NetworkChangeMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.local.bginfomac.network-monitor")
    var onChange: (() -> Void)?

    func start() {
        monitor.pathUpdateHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.onChange?()
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
