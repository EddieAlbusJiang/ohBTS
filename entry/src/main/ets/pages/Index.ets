import { ConnectionState, BluetoothDevice } from '../common/Types';
import { BluetoothManager } from '../common/BluetoothManager';
import { SettingsManager } from '../common/SettingsManager';
import { CommandManager } from '../common/CommandManager';
import { StatusBar } from '../components/StatusBar';
import { DeviceConnectPage } from './DeviceConnectPage';
import { QuickCommandPage } from './QuickCommandPage';
import { SerialPortPage } from './SerialPortPage';

/**
 * 主入口页面
 * 包含状态栏和Tab导航
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State connectionState: ConnectionState = ConnectionState.DISCONNECTED;
  @State connectedDevice: BluetoothDevice | null = null;
  
  private bluetoothManager: BluetoothManager = BluetoothManager.getInstance();
  private settingsManager: SettingsManager = SettingsManager.getInstance();
  private commandManager: CommandManager = CommandManager.getInstance();
  
  async aboutToAppear() {
    // 初始化蓝牙
    await this.bluetoothManager.initialize();
    
    // 立即同步当前状态
    this.connectionState = this.bluetoothManager.connectionState;
    this.connectedDevice = this.bluetoothManager.connectedDevice;
    
    // 设置状态变化回调 - 使用箭头函数确保this绑定正确
    this.bluetoothManager.setOnStateChange((state: ConnectionState, device: BluetoothDevice | null) => {
      // 强制触发状态更新
      this.connectionState = state;
      this.connectedDevice = device;
    });
  }
  
  onPageShow() {
    // 从编辑页面返回时刷新指令列表
    this.commandManager.notifyCommandsChange();
  }
  
  build() {
    Column() {
      // 顶部状态栏
      StatusBar({
        connectionState: this.connectionState,
        connectedDevice: this.connectedDevice
      })
      
      Divider()
      
      // 内容区域
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
      
      // 底部Tab导航
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
  
  /**
   * Tab项
   */
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
