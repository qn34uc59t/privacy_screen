import SceneKit
import AppKit

final class HeadSceneBuilder {
    
    // We keep references to nodes we need to animate later
    let scene = SCNScene()
    let headNode = SCNNode()
    let yawDotNode = SCNNode()
    let pitchDotNode = SCNNode()
    
    init() {
        scene.background.contents = NSColor.clear
        
        setupLighting()
        setupHead()
        setupRings()
    }
    
    private func setupLighting() {
        // Ambient fill
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 150
        ambientLight.color = NSColor(white: 0.8, alpha: 1.0)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Directional rim light
        let dirLight = SCNLight()
        dirLight.type = .directional
        dirLight.intensity = 300
        dirLight.color = NSColor.white
        let dirNode = SCNNode()
        dirNode.light = dirLight
        dirNode.eulerAngles = SCNVector3(x: -CGFloat.pi/4, y: CGFloat.pi/4, z: 0)
        scene.rootNode.addChildNode(dirNode)
    }
    
    private func setupHead() {
        if let url = Bundle.main.url(forResource: "Humanoid_Robot_Face", withExtension: "usdz"),
           let usdzScene = try? SCNScene(url: url, options: nil) {
            
            let robotNode = SCNNode()
            for child in usdzScene.rootNode.childNodes {
                robotNode.addChildNode(child)
            }
            // We no longer override the materials, preserving the original USDZ textures and colors.
            
            // Scale the robot so it fits inside the rings
            let (minVec, maxVec) = robotNode.boundingBox
            
            let height = maxVec.y - minVec.y
            if height > 0 {
                // Scale up the head to fill the rings better
                let targetHeight: CGFloat = 2.6 
                let scale = targetHeight / height
                robotNode.scale = SCNVector3(scale, scale, scale)
                
                // Center the pivot on X, Y (at eye level), and Z so it rotates exactly in place
                let centerX = (maxVec.x + minVec.x) / 2
                let centerY = minVec.y + (height * 0.75) // Move pivot up to eye level
                let centerZ = (maxVec.z + minVec.z) / 2
                
                robotNode.pivot = SCNMatrix4MakeTranslation(centerX, centerY, centerZ)
            }
            
            headNode.addChildNode(robotNode)
            scene.rootNode.addChildNode(headNode)
            
        } else {
            // Fallback to sphere
            let sphere = SCNSphere(radius: 0.5)
            sphere.segmentCount = 48
            let material = SCNMaterial()
            material.fillMode = .lines
            material.diffuse.contents = NSColor.clear
            material.emission.contents = NSColor.white.withAlphaComponent(0.4)
            sphere.materials = [material]
            
            headNode.geometry = sphere
            headNode.scale = SCNVector3(0.78, 1.0, 0.88)
            scene.rootNode.addChildNode(headNode)
        }
    }
    
    private func setupRings() {
        let ringRadius: CGFloat = 1.3
        let pipeRadius: CGFloat = 0.008
        
        // --- Yaw Ring (XZ plane) ---
        let yawRing = SCNTorus(ringRadius: ringRadius, pipeRadius: pipeRadius)
        let yawMat = SCNMaterial()
        yawMat.diffuse.contents = NSColor(red: 0, green: 0.83, blue: 0.78, alpha: 0.4)
        yawMat.emission.contents = NSColor(red: 0, green: 0.83, blue: 0.78, alpha: 0.8)
        yawMat.lightingModel = .constant
        yawRing.materials = [yawMat]
        
        let yawRingNode = SCNNode(geometry: yawRing)
        // Torus is in XZ plane by default, which is correct for yaw.
        scene.rootNode.addChildNode(yawRingNode)
        
        // Yaw Dot
        let yawDot = SCNSphere(radius: 0.03)
        let dotMat = SCNMaterial()
        dotMat.diffuse.contents = NSColor(red: 0, green: 0.83, blue: 0.78, alpha: 1.0)
        dotMat.emission.contents = NSColor.white
        dotMat.lightingModel = .constant
        yawDot.materials = [dotMat]
        
        yawDotNode.geometry = yawDot
        // Start at front (Z axis)
        yawDotNode.position = SCNVector3(0, 0, ringRadius)
        
        yawRingNode.addChildNode(yawDotNode)
        
        // --- Pitch Ring (YZ plane) ---
        let pitchRing = SCNTorus(ringRadius: ringRadius, pipeRadius: pipeRadius)
        // Reuse yawMat so both rings have identical opacity, color, and width appearance
        pitchRing.materials = [yawMat]
        
        let pitchRingNode = SCNNode(geometry: pitchRing)
        // Rotate Torus to YZ plane
        pitchRingNode.eulerAngles = SCNVector3(0, 0, CGFloat.pi / 2)
        scene.rootNode.addChildNode(pitchRingNode)
        
        // Pitch Dot
        let pitchDot = SCNSphere(radius: 0.03)
        pitchDot.materials = [dotMat]
        pitchDotNode.geometry = pitchDot
        
        // For the pitch ring, it's rotated. We'll map the dot appropriately along the circumference.
        // The default torus before rotation is in XZ.
        // Position on the ring: start at the front center intersection
        pitchDotNode.position = SCNVector3(0, 0, ringRadius)
        
        pitchRingNode.addChildNode(pitchDotNode)
    }
}
