import { ConnectionState, BluetoothDevice } from '../common/Types';

@Component
export struct StatusBar {
  @Prop connectionState: ConnectionState = ConnectionState.DISCONNECTED;
  @Prop connectedDevice: BluetoothDevice | null = null;
  @Consume('pathStack') pathStack: NavPathStack;
  
  build() {
    Row() {
      // 连接状态
      Row() {
        // 状态指示灯
        Circle()
          .width(10)
          .height(10)
          .fill(this.getStateColor())
        
        Text(this.getStateText())
          .fontSize(14)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .layoutWeight(1)
      
      // 设置按钮
      Button() {
        Text('设置')
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
      .width(60)
      .height(32)
      .backgroundColor('#007DFF')
      .borderRadius(4)
      .onClick(() => {
        this.pathStack.pushPathByName('SettingsPage', null);
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 获取状态颜色
   */
  private getStateColor(): string {
    switch (this.connectionState) {
      case ConnectionState.CONNECTED:
        return '#00AA00';
      case ConnectionState.CONNECTING:
      case ConnectionState.DISCONNECTING:
        return '#FFAA00';
      case ConnectionState.DISCONNECTED:
      default:
        return '#AAAAAA';
    }
  }
  
  /**
   * 获取状态文本
   */
  private getStateText(): string {
    if (this.connectionState === ConnectionState.CONNECTED && this.connectedDevice) {
      return `已连接 ${this.connectedDevice.deviceName}`;
    }
    return this.connectionState;
  }
}
