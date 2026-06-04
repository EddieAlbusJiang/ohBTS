import { BluetoothDevice, ConnectionState } from '../common/Types';
import { BluetoothManager } from '../common/BluetoothManager';

/**
 * 设备连接页面
 */
@Component
export struct DeviceConnectPage {
  @State discoveredDevices: BluetoothDevice[] = [];
  @State isScanning: boolean = false;
  @State connectionState: ConnectionState = ConnectionState.DISCONNECTED;
  @State connectedDevice: BluetoothDevice | null = null;
  @State filterText: string = '';
  
  private bluetoothManager: BluetoothManager = BluetoothManager.getInstance();
  
  aboutToAppear() {
    // 设置回调
    this.bluetoothManager.setOnDeviceDiscovered((device: BluetoothDevice) => {
      this.discoveredDevices = [...this.bluetoothManager.discoveredDevices];
    });
    
    this.bluetoothManager.setOnStateChange((state: ConnectionState, device: BluetoothDevice | null) => {
      this.connectionState = state;
      this.connectedDevice = device;
    });
    
    // 初始化状态
    this.connectionState = this.bluetoothManager.connectionState;
    this.connectedDevice = this.bluetoothManager.connectedDevice;
    this.discoveredDevices = this.bluetoothManager.discoveredDevices;
  }
  
  aboutToDisappear() {
    // 停止扫描
    if (this.isScanning) {
      this.bluetoothManager.stopDiscovery();
    }
  }
  
  build() {
    Column() {
      // 过滤输入框
      Row() {
        TextInput({ placeholder: '输入设备名称过滤' })
          .width('100%')
          .height(40)
          .backgroundColor(Color.White)
          .borderRadius(4)
          .onChange((value: string) => {
            this.filterText = value;
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5F5F5')
      
      // 扫描按钮
      Row() {
        Button(this.isScanning ? '停止扫描' : '扫描设备')
          .width('100%')
          .height(44)
          .backgroundColor(this.isScanning ? '#FF4444' : '#007DFF')
          .fontColor(Color.White)
          .onClick(() => {
            if (this.isScanning) {
              this.stopScan();
            } else {
              this.startScan();
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
      .backgroundColor('#F5F5F5')
      
      // 设备列表
      if (this.getFilteredDevices().length === 0) {
        Column() {
          Text('暂无设备')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 100 })
        }
        .layoutWeight(1)
        .width('100%')
      } else {
        List() {
          ForEach(this.getFilteredDevices(), (device: BluetoothDevice) => {
            ListItem() {
              this.DeviceItem(device)
            }
          }, (device: BluetoothDevice) => device.deviceId)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(Color.White)
        .divider({ strokeWidth: 1, color: '#EEEEEE' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 设备列表项
   */
  @Builder
  DeviceItem(device: BluetoothDevice) {
    Row() {
      Column() {
        Text(device.deviceName)
          .fontSize(16)
          .fontColor('#333333')
        
        Text(device.deviceId)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 连接状态或连接按钮
      if (this.connectedDevice?.deviceId === device.deviceId) {
        Text('已连接')
          .fontSize(14)
          .fontColor('#00AA00')
      } else {
        Button('连接')
          .width(60)
          .height(32)
          .fontSize(14)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.connectDevice(device);
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }
  
  /**
   * 获取过滤后的设备列表
   */
  private getFilteredDevices(): BluetoothDevice[] {
    if (!this.filterText) {
      return this.discoveredDevices;
    }
    
    return this.discoveredDevices.filter(device => 
      device.deviceName.toLowerCase().includes(this.filterText.toLowerCase())
    );
  }
  
  /**
   * 开始扫描
   */
  private async startScan() {
    this.isScanning = true;
    await this.bluetoothManager.startDiscovery();
    this.discoveredDevices = [...this.bluetoothManager.discoveredDevices];
  }
  
  /**
   * 停止扫描
   */
  private async stopScan() {
    await this.bluetoothManager.stopDiscovery();
    this.isScanning = false;
  }
  
  /**
   * 连接设备
   */
  private async connectDevice(device: BluetoothDevice) {
    await this.bluetoothManager.connectDevice(device);
  }
}
