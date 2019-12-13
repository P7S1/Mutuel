//
// An `ARSCNViewDelegate` which addes and updates the virtual face content in response to the ARFaceTracking session.
//

import SceneKit
import ARKit

class VirtualContentUpdater: NSObject {

    // The virtual content that should be displayed and updated.
    var virtualFaceNode: VirtualFaceNode? {
        didSet {
            setupFaceNodeContent()
        }
    }
    
    // A reference to the node that was added by ARKit in `renderer(_:didAdd:for:)`.
    private var faceNode: SCNNode?
    
    // The queue reference
    private let serialQueue = DispatchQueue(label: "com.svrf.ARKitFaceFilterDemo.serialSceneKitQueue")
    
    //MARK: private functions
    private func setupFaceNodeContent() {
        guard let node = faceNode else {
            return
        }
        
        // Remove all childNodes from the faceNode
        for child in node.childNodes {
            child.removeFromParentNode()
        }

        // Add new content as child node
        if let content = virtualFaceNode {
            node.addChildNode(content)
        }
    }
    
}

// Extension that realises ARSCNViewDelegate protocol's functions
extension VirtualContentUpdater: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        _bufferRenderer?.renderer(renderer, didRenderScene: scene, atTime: time)
        
        if let session = _nextLevel?.arConfiguration?.session,
            let pixelBuffer = _bufferRenderer?.videoBufferOutput {
            _nextLevel?.arSession(session, didRenderPixelBuffer: pixelBuffer, atTime: time)
        }
    }
    
    // ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // Hold onto the `faceNode` so that the session does not need to be restarted when switching face filters.
        faceNode = node
        
        // Put code into async thread
        serialQueue.async {
            
            // Setup face node content
            self.setupFaceNodeContent()
        }
    }
    
    // ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        // FaceAnchor unwrapping
        guard let faceAnchor = anchor as? ARFaceAnchor, let device = renderer.device else { return }
        
        // Update virtualFaceNode with FaceAnchor and MTLDevice
        virtualFaceNode?.update(withFaceAnchor: faceAnchor, andMTLDevice: device)
    }
    
  /*  func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let faceMesh = ARSCNFaceGeometry(device: renderer.device!)
        let node = SCNNode(geometry: faceMesh)
        node.geometry?.firstMaterial?.fillMode = .lines
        return node
    } */
}

extension VirtualContentUpdater : ARSessionDelegate{
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        _nextLevel?.arSession(session, didUpdate: frame)
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    }
    
}
