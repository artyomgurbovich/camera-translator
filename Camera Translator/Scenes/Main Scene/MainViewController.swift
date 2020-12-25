//
//  ViewController.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 9/21/20.
//

import UIKit
import Vision
import CoreMotion

final class MainViewController: UIViewController {
    @IBOutlet weak var cameraOutputView: UIView!
    @IBOutlet weak var fromLanguageTableView: UITableView!
    @IBOutlet weak var fromLanguageTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var fromLanguageTableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var toLanguageTableView: UITableView!
    @IBOutlet weak var toLanguageTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toLanguageTableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var speechButton: UIButton!
    @IBOutlet weak var speechButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var pauseButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var torchButton: UIButton!
    @IBOutlet weak var torchButtonBottomConstraint: NSLayoutConstraint!
    
    private var fromLanguageTableViewSelectedIndexPath: IndexPath!
    private var toLanguageTableViewSelectedIndexPath: IndexPath!
    private let timeIntervalPerPoint = 0.0007
    private let defaultTableViewRowHeight: CGFloat = 50
    private var maxNewTableViewHeight: CGFloat = .zero
    private var uiIsHidden = false
    
    private var cameraManager: CameraManager!
    private var recognizeManager: RecognizeManager!
    private var translateManager: TranslateManager!
    private var textBoxesManager: TextBoxesManager!
    private var speechManager: SpeechManager!
    
    private var currentTextBoxes = [TextBox]()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initManagers()
        setupManagers()
    }
    
    @IBAction func speechButtonTapped() {
        speechManager.speak(textBoxes: currentTextBoxes, language: translateManager.currentToLanguage)
    }
    
    @IBAction func pauseButtonTapped() {
        pauseButton.setImage(cameraManager.isRunning ? UIImage(systemName: "play.fill") : UIImage(systemName: "pause.fill"),
                             for: .normal)
        cameraManager.setRunning(!cameraManager.isRunning)
    }
    
    @IBAction func torchButtonTapped() {
        torchButton.setImage(cameraManager.isTorchOn ? UIImage(systemName: "flashlight.off.fill") : UIImage(systemName: "flashlight.on.fill"),
                             for: .normal)
        cameraManager.toggleTorch()
    }
    
    @objc func screenPressed() {
        closeAllTableViews()
    }
    
    @objc func screenLongPressed(gesture: UIGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIView.animate(withDuration: 150 * timeIntervalPerPoint * 2) {
            self.uiIsHidden.toggle()
            self.fromLanguageTableViewTopConstraint.constant = self.uiIsHidden ? -150 : 25
            self.toLanguageTableViewTopConstraint.constant = self.uiIsHidden ? -150 : 25
            self.speechButtonBottomConstraint.constant = self.uiIsHidden ? -150 : 25
            self.pauseButtonBottomConstraint.constant = self.uiIsHidden ? -150 : 25
            self.torchButtonBottomConstraint.constant = self.uiIsHidden ? -150 : 25
            self.view.layoutIfNeeded()
        }
    }
    
    func initManagers() {
        guard let cameraManager = CameraManager(outputView: cameraOutputView) else {
            showAlert(title: "Error", message: "Camera manager not initialized!")
            return
        }
        self.cameraManager = cameraManager
        guard let recognizeManager = RecognizeManager(recognizeRectSize: cameraOutputView.bounds.size) else {
            showAlert(title: "Error", message: "Recognize manager not initialized!")
            return
        }
        self.recognizeManager = recognizeManager
        guard let speechManager = SpeechManager() else {
            showAlert(title: "Error", message: "Speech manager not initialized!")
            return
        }
        self.speechManager = speechManager
        let fromLanguages = RecognizeManager.availableLanguages
        let toLanguages = SpeechManager.availableLanguages
        guard let translateManager = TranslateManager(fromLanguages: fromLanguages, toLanguages: toLanguages) else {
            showAlert(title: "Error", message: "Translate manager not initialized!")
            return
        }
        self.translateManager = translateManager
        guard let textBoxesManager = TextBoxesManager(rectWidth: cameraOutputView.bounds.width) else {
            showAlert(title: "Error", message: "Text boxes manager not initialized!")
            return
        }
        self.textBoxesManager = textBoxesManager
    }
    
    func setupManagers() {
        setupTranslateManager()
        cameraManager.onMove = {
            print("4) Move camera")
            self.currentTextBoxes.removeAll()
            self.speechManager.stopSpeaking()
            self.translateManager.stopTranslate()
            self.cameraManager.clearPreviewLayer()
            self.cameraManager.setReceiving(true)
        }
        cameraManager.onReceive = { frame in
            print("1) Receive frame from camera")
            self.cameraManager.setReceiving(false)
            self.recognizeManager.recognize(by: frame)
        }
        recognizeManager.onRecognize = { textBoxes in
            print("2) Recognize text in frame")
            if !textBoxes.isEmpty {
                self.translateManager.translate(textBoxes: textBoxes)
            } else {
                self.cameraManager.setReceiving(true)
            }
        }
        translateManager.onTranslate = { textBoxes in
            print("3) Translate recognized text")
            self.currentTextBoxes = textBoxes
            let layers = self.textBoxesManager.updateLayout(textBoxes: textBoxes)
            self.cameraManager.draw(layers: layers)
        }
    }
    
    func setupTranslateManager() {
        let fromLanguageIndexPath = IndexPath(row: translateManager.getLanguageIndex(ofType: .from, by: "en")!, section: .zero)
        let toLanguageIndexPath = IndexPath(row: translateManager.getLanguageIndex(ofType: .to, by: "ru")!, section: .zero)
        translateManager.setCurrentLanguage(ofType: .from, by: fromLanguageIndexPath.row)
        translateManager.setCurrentLanguage(ofType: .to, by: toLanguageIndexPath.row)
        fromLanguageTableView.selectRow(at: fromLanguageIndexPath, animated: false, scrollPosition: .top)
        toLanguageTableView.selectRow(at: toLanguageIndexPath, animated: false, scrollPosition: .top)
        fromLanguageTableView.deselectRow(at: fromLanguageIndexPath, animated: false)
        toLanguageTableView.deselectRow(at: toLanguageIndexPath, animated: false)
    }
    
    func setupUI() {
        let screenTap = UITapGestureRecognizer(target: self, action: #selector(screenPressed))
        view.addGestureRecognizer(screenTap)
        screenTap.delegate = self
        let screenLongPress = UILongPressGestureRecognizer(target: self, action: #selector(screenLongPressed(gesture:)))
        view.addGestureRecognizer(screenLongPress)
        screenLongPress.delegate = self
        maxNewTableViewHeight = CGFloat(Int((view.bounds.height / 2) / defaultTableViewRowHeight)) * defaultTableViewRowHeight
        fromLanguageTableView.delegate = self
        fromLanguageTableView.dataSource = self
        fromLanguageTableView.rowHeight = defaultTableViewRowHeight
        fromLanguageTableView.layer.borderColor = UIColor.white.cgColor
        fromLanguageTableView.addShadow()
        toLanguageTableView.delegate = self
        toLanguageTableView.dataSource = self
        toLanguageTableView.rowHeight = defaultTableViewRowHeight
        toLanguageTableView.layer.borderColor = UIColor.white.cgColor
        toLanguageTableView.addShadow()
        speechButton.addShadow()
        speechButton.layer.borderWidth = .zero
        speechButton.layer.borderColor = UIColor.white.cgColor
        pauseButton.addShadow()
        pauseButton.layer.borderWidth = .zero
        pauseButton.layer.borderColor = UIColor.white.cgColor
        torchButton.addShadow()
        torchButton.layer.borderWidth = .zero
        torchButton.layer.borderColor = UIColor.white.cgColor
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        saveSelectedIndexPath(of: tableView, indexPath: indexPath)
        if tableView.bounds.height == defaultTableViewRowHeight {
            closeAllTableViews()
            openTableView(tableView)
            tableView.isScrollEnabled = true
        } else {
            closeTableView(tableView, on: indexPath)
            tableView.isScrollEnabled = false
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func saveSelectedIndexPath(of tableView: UITableView, indexPath: IndexPath) {
        switch tableView {
        case fromLanguageTableView:
            fromLanguageTableViewSelectedIndexPath = indexPath
        case toLanguageTableView:
            toLanguageTableViewSelectedIndexPath = indexPath
        default:
            break
        }
    }
    
    func closeAllTableViews() {
        if fromLanguageTableView.bounds.height != defaultTableViewRowHeight {
            closeTableView(fromLanguageTableView, on: fromLanguageTableViewSelectedIndexPath)
        } else if toLanguageTableView.bounds.height != defaultTableViewRowHeight {
            closeTableView(toLanguageTableView, on: toLanguageTableViewSelectedIndexPath)
        }
    }
    
    func openTableView(_ tableView: UITableView) {
        let numberOfRows = CGFloat(tableView.numberOfRows(inSection: .zero))
        let newHeight = min(numberOfRows * defaultTableViewRowHeight, maxNewTableViewHeight)
        switch tableView {
        case fromLanguageTableView:
            fromLanguageTableViewHeightConstraint.constant = newHeight
        case toLanguageTableView:
            toLanguageTableViewHeightConstraint.constant = newHeight
        default:
            break
        }
        UIView.animate(withDuration: timeIntervalPerPoint * Double(newHeight), delay: .zero, options: .curveLinear) {
            self.view.layoutIfNeeded()
        }
    }
    
    func closeTableView(_ tableView: UITableView, on indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowPositionY = tableView.rectForRow(at: indexPath).maxY
        let rowPositionYWithoutOffset = rowPositionY - tableView.contentOffset.y
        let distanceBeforeRow = Double(tableView.bounds.height - rowPositionYWithoutOffset)
        let distanceAfterRow = Double(rowPositionYWithoutOffset - defaultTableViewRowHeight)
        var heightConstraint = NSLayoutConstraint()
        var languageTranslationType = TranslateManager.LanguageTranslationType.from
        switch tableView {
        case fromLanguageTableView:
            heightConstraint = fromLanguageTableViewHeightConstraint
        case toLanguageTableView:
            heightConstraint = toLanguageTableViewHeightConstraint
            languageTranslationType = .to
        default:
            break
        }
        translateManager.setCurrentLanguage(ofType: languageTranslationType, by: indexPath.row)
        heightConstraint.constant = rowPositionYWithoutOffset
        UIView.animate(withDuration: timeIntervalPerPoint * 2 * distanceBeforeRow, delay: .zero, options: .curveLinear, animations: self.view.layoutIfNeeded) { _ in
            UIView.animate(withDuration: self.timeIntervalPerPoint * 2 * distanceAfterRow, delay: .zero, options: .curveLinear) {
                heightConstraint.constant = self.defaultTableViewRowHeight
                tableView.setContentOffset(CGPoint(x: .zero, y: rowPositionY - self.defaultTableViewRowHeight), animated: false)
                self.view.layoutIfNeeded()
            }
        }
        UIView.animate(withDuration: timeIntervalPerPoint * 2 * (distanceBeforeRow + distanceAfterRow), delay: .zero, options: .curveLinear) {
            self.view.layoutIfNeeded()
        }
    }
    
    func updateLanguage(ofType type: TranslateManager.LanguageTranslationType, by index: Int) {
        translateManager.setCurrentLanguage(ofType: type, by: index)
        if type == .from {
            recognizeManager.setRecognizeLanguage(translateManager.currentFromLanguage)
        }
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case fromLanguageTableView:
            return translateManager.fromLanguages.count
        case toLanguageTableView:
            return translateManager.toLanguages.count
        default:
            return .zero
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        switch tableView {
        case fromLanguageTableView:
            cell.textLabel?.text = translateManager.fromLanguages.map{$0.name}[indexPath.row]
        case toLanguageTableView:
            cell.textLabel?.text = translateManager.toLanguages.map{$0.name}[indexPath.row]
        default:
            break
        }
        return cell
    }
}

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view,
            view.isDescendant(of:   toLanguageTableView) ||
            view.isDescendant(of: fromLanguageTableView) ||
            view.isDescendant(of:          speechButton) ||
            view.isDescendant(of:           pauseButton) ||
            view.isDescendant(of:           torchButton) {
            return false
        }
        return true
    }
}
