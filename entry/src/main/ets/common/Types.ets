/**
 * 蓝牙设备信息
 */
export interface BluetoothDevice {
  deviceId: string;
  deviceName: string;
  rssi: number;
}

/**
 * 连接状态
 */
export enum ConnectionState {
  DISCONNECTED = '未连接',
  CONNECTING = '连接中',
  CONNECTED = '已连接',
  DISCONNECTING = '断开中'
}

/**
 * 串口数据类型
 */
export interface SerialData {
  content: string;
  isSend: boolean; // true: 发送, false: 接收
  timestamp: number;
  displayMode: DisplayMode;
}

/**
 * 显示模式
 */
export enum DisplayMode {
  ASCII = 'ASCII',
  HEX = 'Hex'
}

/**
 * 快捷指令
 */
export interface QuickCommand {
  id: string;
  name: string;
  content: string;
  displayMode: DisplayMode;
  repeatCount: number;
}
