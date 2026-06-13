import { ConnectionState, BluetoothDevice } from '../common/Types';
import { BluetoothManager } from '../common/BluetoothManager';
import { SettingsManager } from '../common/SettingsManager';
import { CommandManager } from '../common/CommandManager';
import { StatusBar } from '../components/StatusBar';
import { DeviceConnectPage } from './DeviceConnectPage';
import { QuickCommandPage } from './QuickCommandPage';
import { SerialPortPage } from './SerialPortPage';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State connectionState: ConnectionState = ConnectionState.DISCONNECTED;
  @State connectedDevice: BluetoothDevice | null = null;
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();
  
  private bluetoothManager: BluetoothManager = BluetoothManager.getInstance();
  private settingsManager: SettingsManager = SettingsManager.getInstance();
  private commandManager: CommandManager = CommandManager.getInstance();
  
  async aboutToAppear() {
    await this.bluetoothManager.initialize();
    
    this.connectionState = this.bluetoothManager.connectionState;
    this.connectedDevice = this.bluetoothManager.connectedDevice;
    
    this.bluetoothManager.setOnStateChange((state: ConnectionState, device: BluetoothDevice | null) => {
      this.connectionState = state;
      this.connectedDevice = device;
    });
  }
  
  onPageShow() {
    this.commandManager.notifyCommandsChange();
  }
  
  build() {
    Navigation(this.pathStack) {
      Column() {
        StatusBar({
          connectionState: this.connectionState,
          connectedDevice: this.connectedDevice
        })
        
        Divider()
        
        Column() {
          if (this.currentIndex === 0) {
            DeviceConnectPage()
          } else if (this.currentIndex === 1) {
            QuickCommandPage()
          } else {
            SerialPortPage()
          }
        }
        .layoutWeight(1)
        
        Divider()
        
        Row() {
          this.TabItem('设备连接', 0)
          this.TabItem('快捷命令', 1)
          this.TabItem('常规串口', 2)
        }
        .width('100%')
        .height(56)
        .backgroundColor(Color.White)
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
  
  @Builder
  TabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = index;
    })
  }
}
