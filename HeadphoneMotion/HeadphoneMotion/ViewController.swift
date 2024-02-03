//
//  ViewController.swift
//  HeadphoneMotion
//
//  Created by yangjie.layer on 2024/2/3.
//

import UIKit

class ViewController: UIViewController {
    
    enum Target: Int {
        case coreMotion
        case feed
    }
    
    let items = [(Target.coreMotion, "CoreMotionViewController"),
                 (Target.feed, "FeedViewController")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].1
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        let targetViewController: UIViewController
        switch item.0 {
        case .coreMotion:
            targetViewController = CoreMotionViewController()
        case .feed:
            targetViewController = FeedViewController()
        }
        navigationController?.pushViewController(targetViewController, animated: true)
    }
}

