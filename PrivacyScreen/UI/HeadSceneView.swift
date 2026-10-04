import SwiftUI
import SceneKit

struct HeadSceneView: NSViewRepresentable {
    @Bindable var motionState: MotionState
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        scnView.isJitteringEnabled = true
        
        let builder = HeadSceneBuilder()
        scnView.scene = builder.scene
        
        // Setup Camera
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 100
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 2.3)
        builder.scene.rootNode.addChildNode(cameraNode)
        
        context.coordinator.builder = builder
        
        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        guard let builder = context.coordinator.builder else { return }
        
        let yaw = CGFloat(motionState.deltaYaw)
        let pitch = CGFloat(motionState.deltaPitch)
        
        // Smoothly animate the changes via SCNTransaction
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.08
        
        // Head rotation: -pitch for X axis (nodding), -yaw for Y axis (shaking head)
        builder.headNode.eulerAngles = SCNVector3(-pitch, -yaw, 0)
        
        // Yaw Dot on the XZ ring (radius 0.75)
        // Center is at front (0, 0, r). As yaw changes, we move around the ring.
        // We use sin/cos to map the angle.
        let r: CGFloat = 1.3
        builder.yawDotNode.position = SCNVector3(-sin(yaw) * r, 0, cos(yaw) * r)
        
        // Pitch Dot on the YZ ring. 
        // The pitch ring is rotated to the YZ plane (rotated pi/2 on Z axis).
        // Global Y maps to local X. Looking up (pitch > 0) means dot moves up (local X > 0).
        builder.pitchDotNode.position = SCNVector3(sin(pitch) * r, 0, cos(pitch) * r)
        
        SCNTransaction.commit()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var builder: HeadSceneBuilder?
    }
}
