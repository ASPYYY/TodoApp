import UIKit
import AVFoundation
import Speech

final class TaskListViewController: UIViewController {
    
    var presenter: TaskListPresenterProtocol?
    private var tasks: [TaskEntity] = []
    
    // MARK: - Speech
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isRecording = false
    private var audioTapInstalled = false
    
    // MARK: - UI Elements
    
    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Задачи"
        lbl.font = .systemFont(ofSize: 34, weight: .bold)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.barStyle = .black
        sb.searchBarStyle = .minimal
        sb.showsCancelButton = false
        sb.translatesAutoresizingMaskIntoConstraints = false
        sb.delegate = self
        
        let micButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        micButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)
        micButton.tintColor = UIColor.white.withAlphaComponent(0.5)
        micButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        sb.searchTextField.rightView = micButton
        sb.searchTextField.rightViewMode = .always
        
        return sb
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .black
        tv.separatorColor = UIColor.white.withAlphaComponent(0.1)
        tv.register(TaskCell.self, forCellReuseIdentifier: TaskCell.identifier)
        tv.delegate = self
        tv.dataSource = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private lazy var addButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let image = UIImage(systemName: "square.and.pencil", withConfiguration: config)
        btn.setImage(image, for: .normal)
        btn.tintColor = .systemYellow
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var taskCountLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor.white.withAlphaComponent(0.6)
        lbl.font = .systemFont(ofSize: 14)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.1, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // MARK: - Status Bar
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter?.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadTasks),
            name: .taskSaved,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.didSearchTasks(query: searchBar.text ?? "")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        navigationController?.navigationBar.isHidden = true
        
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(bottomBar)
        bottomBar.addSubview(taskCountLabel)
        bottomBar.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 83),
            
            taskCountLabel.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            taskCountLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor, constant: -16),
            
            addButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func addTapped() {
        presenter?.didTapAddTask()
    }
    
    @objc private func reloadTasks() {
        presenter?.didSearchTasks(query: searchBar.text ?? "")
    }
    
    // MARK: - Voice Search
    
    @objc private func micTapped() {
        if isRecording {
            stopRecording()
        } else {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.startRecording()
                    } else {
                        self?.showError("Нет доступа к микрофону или распознаванию речи")
                    }
                }
            }
        }
    }
    
    private func tearDownAudioTap() {
        guard audioTapInstalled else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioTapInstalled = false
    }
    
    private func startRecording() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            showError("Распознавание речи недоступно на этом устройстве")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            showError("Микрофон недоступен (на симуляторе включите звук или проверьте настройки)")
            return
        }
        
        isRecording = true
        updateMicButton(recording: true)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioTapInstalled = true
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            tearDownAudioTap()
            isRecording = false
            updateMicButton(recording: false)
            showError("Не удалось начать запись с микрофона")
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.searchBar.text = text
                    self.presenter?.didSearchTasks(query: text)
                    self.searchBar.setShowsCancelButton(!text.isEmpty, animated: true)
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async { self.stopRecording() }
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        tearDownAudioTap()
        updateMicButton(recording: false)
    }
    
    private func updateMicButton(recording: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iconName = recording ? "stop.circle.fill" : "mic.fill"
        let color: UIColor = recording ? .systemRed : UIColor.white.withAlphaComponent(0.5)
        if let micButton = searchBar.searchTextField.rightView as? UIButton {
            micButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
            micButton.tintColor = color
        }
    }
}

// MARK: - TaskListViewProtocol

extension TaskListViewController: TaskListViewProtocol {
    
    func showTasks(_ tasks: [TaskEntity]) {
        self.tasks = tasks
        taskCountLabel.text = "\(tasks.count) Задач"
    }
    
    func reloadTable() {
        tableView.reloadData()
    }
    
    func deleteTask(at index: Int) {
        guard index < tableView.numberOfRows(inSection: 0) else {
            tableView.reloadData()
            return
        }
        tableView.performBatchUpdates {
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension TaskListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TaskCell.identifier,
            for: indexPath
        ) as! TaskCell
        cell.configure(with: tasks[indexPath.row])
        cell.onToggle = { [weak self] in
            guard let self else { return }
            self.presenter?.didToggleComplete(self.tasks[indexPath.row])
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TaskListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter?.didTapTask(tasks[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        let task = tasks[indexPath.row]
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: { TaskPreviewViewController(task: task) },
            actionProvider: { [weak self] _ in
                let edit = UIAction(
                    title: "Редактировать",
                    image: UIImage(systemName: "pencil")
                ) { _ in self?.presenter?.didTapTask(task) }
                
                let share = UIAction(
                    title: "Поделиться",
                    image: UIImage(systemName: "square.and.arrow.up")
                ) { [weak self] _ in
                    let text = "\(task.title ?? "")\n\(task.desc ?? "")"
                    let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                    self?.present(vc, animated: true)
                }
                
                let delete = UIAction(
                    title: "Удалить",
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { _ in self?.presenter?.didDeleteTask(task) }
                
                return UIMenu(title: "", children: [edit, share, delete])
            }
        )
    }
}

// MARK: - UISearchBarDelegate

extension TaskListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter?.didSearchTasks(query: searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        let hasText = !(searchBar.text?.isEmpty ?? true)
        searchBar.setShowsCancelButton(hasText, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        presenter?.didSearchTasks(query: "")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - TaskPreviewViewController

final class TaskPreviewViewController: UIViewController {
    
    init(task: TaskEntity) {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = UIColor(white: 0.15, alpha: 1)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        title.text = task.title
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.textColor = .white
        title.numberOfLines = 0
        
        let date = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        date.text = formatter.string(from: task.createdAt ?? Date())
        date.font = .systemFont(ofSize: 13)
        date.textColor = .systemGray
        
        let desc = UILabel()
        desc.text = task.desc
        desc.font = .systemFont(ofSize: 15)
        desc.textColor = UIColor.white.withAlphaComponent(0.8)
        desc.numberOfLines = 0
        
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(date)
        stack.addArrangedSubview(desc)
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            preferredContentSize = CGSize(width: scene.screen.bounds.width - 40, height: 200)
        } else {
            preferredContentSize = CGSize(width: 335, height: 200)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
