//
// `VirtualFaceContent` provides an interface for the content in this sample to update in response to
// tracking changes.
//

import ARKit
import SceneKit

protocol VirtualFaceContent {
    func update(withFaceAnchor: ARFaceAnchor, andMTLDevice device: MTLDevice)
}

// Mark VirtualFaceContent and SCNNode as VirtualFaceNode
typealias VirtualFaceNode = VirtualFaceContent & SCNNode
