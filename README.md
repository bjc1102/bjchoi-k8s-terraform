# bjchoi-k8s-terraform
각 워커노드에 아래 명령을 수행하여야 합니다.

```bash
kubeadm token create --print-join-command

kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/kubelet.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
